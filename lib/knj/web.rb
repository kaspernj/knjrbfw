# encoding: utf-8

require "php4r" if !Kernel.const_defined?(:Php4r)

class Knj::Web
  #Parses URI and returns hash with data.
  def self.parse_uri(str)
    uri_match = str.to_s.match(/^\/(.+?\..*?|)(\?(.*)|)$/)
    raise "Could not parse the URI: '#{str}'." if !uri_match
    
    return {
      :path => "/#{uri_match[1]}",
      :query => uri_match[3]
    }
  end
  
  #Parses cookies-string and returns hash with parsed cookies.
  def self.parse_cookies(str)
    ret = {}
    
    str.split(/;\s*/).each do |cookie_str|
      if !match = cookie_str.match(/^(.*?)=\"(.*)\"$/)
        match = cookie_str.match(/^(.*?)=(.*)$/)
      end
      
      ret[self.urldec(match[1])] = self.urldec(match[2]) if match
    end
    
    return ret
  end
  
  def self.parse_set_cookies(str)
    str = String.new(str.to_s)
    return [] if str.length <= 0
    args = {}
    cookie_start_regex = /^(.+?)=(.*?)(;\s*|$)/
    
    match = str.match(cookie_start_regex)
    raise "Could not match cookie: '#{str}'." if !match
    str.gsub!(cookie_start_regex, "")
    
    args["name"] = self.urldec(match[1].to_s)
    args["value"] = self.urldec(match[2].to_s)
    
    while match = str.match(/(.+?)=(.*?)(;\s*|$)/)
      str = str.gsub(match[0], "")
      args[match[1].to_s.downcase] = match[2].to_s
    end
    
    return [args]
  end
  
  def self.cookie_str(cookie_data)
    raise "Not a hash: '#{cookie_data.class.name}', '#{cookie_data}'." unless cookie_data.is_a?(Hash)
    cookiestr = "#{self.urlenc(cookie_data["name"])}=#{self.urlenc(cookie_data["value"])}"
    
    cookie_data.each do |key, val|
      next if key == "name" or key == "value"
      
      if key.to_s.downcase == "expires" and val.is_a?(Time)
        cookiestr << "; Expires=#{val.httpdate}"
      else
        cookiestr << "; #{key}=#{val}"
      end
    end
    
    return cookiestr
  end
  
  #Parses a query and returns the various _GET-variables.
  def self.parse_urlquery(querystr, args = {})
    get = {}
    querystr.to_s.split("&").each do |value|
      pos = value.index("=")
      
      if pos != nil
        name = value[0..pos-1]
        name = name.to_sym if args[:syms]
        valuestr = value.slice(pos+1..-1)
        Knj::Web.parse_name(get, Knj::Web.urldec(name), valuestr, args)
      end
    end
    
    return get
  end
  
  def self.parse_name(seton, varname, value, args = {})
    if value.respond_to?(:filename) and value.filename
      realvalue = value
    else
      realvalue = value.to_s
      realvalue = self.urldec(realvalue) if args[:urldecode]
      realvalue = realvalue.force_encoding("utf-8") if args[:force_utf8] if realvalue.respond_to?(:force_encoding)
    end
    
    if varname and varname.index("[") != nil and match = varname.match(/\[(.*?)\]/)
      namepos = varname.index(match[0])
      name = varname.slice(0..namepos - 1)
      name = name.to_sym if args[:syms]
      seton[name] = {} if !seton.key?(name)
      
      secname, secname_empty = Knj::Web.parse_secname(seton[name], match[1], args)
      
      valuefrom = namepos + secname.to_s.length + 2
      restname = varname.slice(valuefrom..-1)
      
      if restname and restname.index("[") != nil
        seton[name][secname] = {} if !seton[name].key?(secname)
        Knj::Web.parse_name_second(seton[name][secname], restname, value, args)
      else
        seton[name][secname] = realvalue
      end
    else
      seton[varname] = realvalue
    end
  end
  
  def self.parse_secname(seton, secname, args)
    secname_empty = false
    if secname.length <= 0
      secname_empty = true
      try = 0
      
      loop do
        if !seton.key?(try.to_s)
          break
        else
          try += 1
        end
      end
      
      secname = try.to_s
    end
    
    secname = secname.to_sym if args[:syms] and secname.is_a?(String) and !(Float(secname) rescue false)
    return [secname, secname_empty]
  end
  
  def self.parse_name_second(seton, varname, value, args = {})
    if value.respond_to?(:filename) and value.filename
      realvalue = value
    else
      realvalue = value.to_s
      realvalue = realvalue.force_encoding("utf-8") if args[:force_utf8]
    end
    
    match = varname.match(/^\[(.*?)\]/)
    if match
      namepos = varname.index(match[0])
      name = match[1]
      secname, secname_empty = Knj::Web.parse_secname(seton, match[1], args)
      
      valuefrom = namepos + match[1].length + 2
      restname = varname.slice(valuefrom..-1)
      
      if restname and restname.index("[") != nil
        seton[secname] = {} if !seton.key?(secname)
        Knj::Web.parse_name_second(seton[secname], restname, value, args)
      else
        seton[secname] = realvalue
      end
    else
      seton[varname] = realvalue
    end
  end
  
  def self.require_eruby(filepath)
    cont = File.read(filepath).untaint
    parse = Erubis.Eruby.new(cont)
    eval(parse.src.to_s)
  end
  
  def self.alert(string)
    require "#{$knjpath}strings"
    
    begin
      _httpsession.alert_sent = true
    rescue NameError
      #ignore.
    end
    
    @alert_sent = true
    
    html = "<script type=\"text/javascript\">alert(\"#{Knj::Strings.js_safe(string.to_s)}\");</script>"
    print html
    
    return self
  end
  
  #Redirects to another URL.
  #===Examples
  #  Knj::Web.redirect("someotherpage.rhtml")
  #  Knj::Web.redirect("newpage.rhtml", :perm => true)
  def self.redirect(url, args = {})
    #Header way
    begin
      if !_httpsession.alert_sent and !_hb.headers_sent?
        if args[:perm]
          _httpsession.resp.status = 301 if !_hb.headers_sent?
        else
          _httpsession.resp.status = 303 if !_hb.headers_sent?
        end
        
        _hb.header("Location", url) if !_hb.headers_sent?
      end
    rescue NameError
      #ignore.
    end
    
    print "<script type=\"text/javascript\">location.href=\"#{url}\";</script>"
    exit
  end
  
  def self.back
    print "<script type=\"text/javascript\">history.go(-1);</script>"
    exit
  end
  
  def self.checkval(value, val1, val2 = nil)
    if val2 != nil
      if !value or value == "" or value == "false"
        return val2
      else
        return val1
      end
    else
      if !value or value == "" or value == "false"
        return val1
      else
        return value
      end
    end
  end
  
  def self.inputs(arr)
    html = ""
    arr.each do |args|
      if RUBY_ENGINE == "rbx"
        html << self.input(args).to_s.encode(html.encoding)
      else
        html << self.input(args)
      end
    end
    
    return html
  end
  
  def self.style_html(css)
    return "" if css.length <= 0
    
    str = " style=\""
    
    css.each do |key, val|
      str << "#{key}: #{val};"
    end
    
    str << "\""
    
    return str
  end
  
  def self.attr_html(attrs)
    return "" if attrs.length <= 0
    
    html = ""
    attrs.each do |key, val|
      html << " #{key}=\"#{val.to_s.html}\""
    end
    
    return html
  end
  
  def self.input(args)
    Knj::ArrayExt.hash_sym(args)
    
    if args.key?(:value)
      if args[:value].is_a?(Array) and (args[:value].first.is_a?(NilClass) or args[:value].first == false)
        value = nil
      elsif args[:value].is_a?(Array)
        if !args[:value][2] or args[:value][2] == :key
          value = args[:value].first[args[:value][1]]
        elsif args[:value][2] == :callb
          value = args[:value].first.send(args[:value][1])
        else
          value = args[:value]
        end
      elsif args[:value].is_a?(String) or args[:value].is_a?(Integer)
        value = args[:value].to_s
      else
        value = args[:value]
      end
    end
    
    args[:value_default] = args[:default] if args[:default]
    
    if value.is_a?(NilClass) and args[:value_default]
      value = args[:value_default]
    elsif value.is_a?(NilClass)
      value = ""
    end
    
    if value and args.key?(:value_func) and args[:value_func]
      cback = args[:value_func]
      
      if cback.is_a?(Method)
        value = cback.call(value)
      elsif cback.is_a?(Array)
        value = Php4r.call_user_func(args[:value_func], value)
      elsif cback.is_a?(Proc)
        value = cback.call(value)
      else
        raise "Unknown class: #{cback.class.name}."
      end
    end
    
    value = args[:values] if args[:values]
    args[:id] = args[:name] if !args[:id]
    
    if !args[:type]
      if args[:opts]
        args[:type] = :select
      elsif args[:name] and args[:name].to_s[0..2] == "che"
        args[:type] = :checkbox
      elsif args[:name] and args[:name].to_s[0..3] == "file"
        args[:type] = :file
      else
        args[:type] = :text
      end
    else
      args[:type] = args[:type].to_sym
    end
    
    attr = {
      "name" => args[:name],
      "id" => args[:id],
      "type" => args[:type],
      "class" => "input_#{args[:type]}"
    }
    attr.merge!(args[:attr]) if args[:attr]
    attr["disabled"] = "disabled" if args[:disabled]
    attr["maxlength"] = args[:maxlength] if args.key?(:maxlength)
    
    raise "No name given to the Web::input()-method." if !args[:name] and args[:type] != :info and args[:type] != :textshow and args[:type] != :plain and args[:type] != :spacer and args[:type] != :headline
    
    css = {}
    css["text-align"] = args[:align] if args.key?(:align)
    css.merge!(args[:css]) if args.key?(:css)
    
    attr_keys = [:onchange]
    attr_keys.each do |tag|
      if args.key?(tag)
        attr[tag] = args[tag]
      end
    end
    
    classes_tr = []
    classes_tr += args[:classes_tr] if args[:classes_tr]
    
    if !classes_tr.empty?
      classes_tr_html = " class=\"#{classes_tr.join(" ")}\""
    else
      classes_tr_html = ""
    end
    
    if args.key?(:title)
      title_html = args[:title].to_s.html
    elsif args.key?(:title_html)
      title_html = args[:title_html]
    end
    
    html = ""
    
    classes = ["input_#{args[:type]}"]
    classes = classes | args[:classes] if args.key?(:classes)
    attr["class"] = classes.join(" ")
    
    if args[:type] == :checkbox
      attr["value"] = args[:value_active] if args.key?(:value_active)
      attr["checked"] = "checked" if value.is_a?(String) and value == "1" or value.to_s == "1" or value.to_s == "on" or value.to_s == "true"
      attr["checked"] = "checked" if value.is_a?(TrueClass)
      
      html << "<tr#{classes_tr_html}>"
      html << "<td colspan=\"2\" class=\"tdcheck\">"
      html << "<input#{self.attr_html(attr)} />"
      html << "<label for=\"#{args[:id].html}\">#{title_html}</label>"
      html << "</td>"
      html << "</tr>"
    elsif args[:type] == :headline
      html << "<tr#{classes_tr_html}><td colspan=\"2\"><h2 class=\"input_headline\">#{title_html}</h2></td></tr>"
    elsif args[:type] == :spacer
      html << "<tr#{classes_tr_html}><td colspan=\"2\">&nbsp;</td></tr>"
    else
      html << "<tr#{classes_tr_html} id=\"#{Knj::Web.html("#{args[:id]}_tr")}\">"
      html << "<td class=\"tdt\" id=\"#{Knj::Web.html("#{args[:id]}_label")}\"><div>"
      html << title_html
      html << "</div></td>"
      html << "<td#{self.style_html(css)} class=\"tdc\" id=\"#{Knj::Web.html("#{args[:id]}_content")}\"><div>"
      
      if args[:type] == :textarea
        if args.key?(:height)
          if (Float(args[:height]) rescue false)
            css["height"] = "#{args[:height]}px"
          else
            css["height"] = args[:height]
          end
        end
        
        html << "<textarea#{self.style_html(css)} class=\"input_textarea\" name=\"#{args[:name].html}\" id=\"#{args[:id].html}\">#{value}</textarea>"
      elsif args[:type] == :fckeditor
        args[:height] = 400 if !args[:height]
        
        require "/usr/share/fckeditor/fckeditor.rb" if !Kernel.const_defined?(:FCKeditor)
        fck = FCKeditor.new(args[:name])
        fck.Height = args[:height].to_i
        fck.Value = value
        html << fck.CreateHtml
      elsif args[:type] == :ckeditor
        args[:height] = 400 if !args[:height]
        require "ckeditor4ruby" if !Kernel.const_defined?(:CKEditor)
        ck = CKEditor.new
        ck.return_output = true
        html << ck.editor(args[:name], value)
      elsif args[:type] == :select
        attr["multiple"] = "multiple" if args[:multiple]
        attr["size"] = args["size"] if args[:size]
        
        html << "<select#{self.attr_html(attr)}>"
        html << Knj::Web.opts(args[:opts], value, args[:opts_args])
        html << "</select>"
        
        if args[:moveable]
          html << "<div style=\"padding-top: 3px;\">"
          html << "<input type=\"button\" value=\"#{_("Up")}\" onclick=\"select_moveup($('##{args[:id]}'));\" />"
          html << "<input type=\"button\" value=\"#{_("Down")}\" onclick=\"select_movedown($('##{args[:id]}'));\" />"
          html << "</div>"
        end
      elsif args[:type] == :imageupload
        html << "<table class=\"designtable\"><tr#{classes_tr_html}><td style=\"width: 100%;\">"
        html << "<input type=\"file\" name=\"#{args[:name].html}\" class=\"input_file\" />"
        html << "</td><td style=\"padding-left: 5px;\">"
        
        raise "No path given for imageupload-input." if !args.key?(:path)
        raise "No value given in arguments for imageupload-input." if !args.key?(:value)
        
        path = args[:path].gsub("%value%", value.to_s).untaint
        if File.exists?(path)
          html << "<img src=\"image.rhtml?path=#{self.urlenc(path).html}&smartsize=100&rounded_corners=10&border_color=black&force=true&ts=#{Time.new.to_f}\" alt=\"Image\" />"
          
          if args[:dellink]
            dellink = args[:dellink].gsub("%value%", value.to_s)
            html << "<div style=\"text-align: center;\">(<a href=\"javascript: if (confirm('#{_("Do you want to delete the image?")}')){location.href='#{dellink}';}\">#{_("delete")}</a>)</div>"
          end
        end
        
        html << "</td></tr></table>"
      elsif args[:type] == :file
        html << "<input type=\"#{args[:type].to_s}\" class=\"input_#{args[:type].to_s}\" name=\"#{args[:name].html}\" />"
      elsif args[:type] == :textshow or args[:type] == :info
        html << value.to_s
      elsif args[:type] == :plain
        html << "#{Php4r.nl2br(Knj::Web.html(value))}"
      elsif args[:type] == :editarea
        css["width"] = "100%"
        css["height"] = args[:height] if args.key?(:height)
        html << "<textarea#{self.attr_html(attr)}#{self.style_html(css)} id=\"#{args[:id]}\" name=\"#{args[:name]}\">#{value}</textarea>"
        
        jshash = {
          "id" => args[:id],
          "start_highlight" => true
        }
        
        pos_keys = [:skip_init, :allow_toggle, :replace_tab_by_spaces, :toolbar, :syntax]
        pos_keys.each do |key|
          jshash[key.to_s] = args[key] if args.key?(key)
        end
        
        html << "<script type=\"text/javascript\">"
        html << "function knj_web_init_#{args[:name]}(){"
        html << "editAreaLoader.init(#{Php4r.json_encode(jshash)});"
        html << "}"
        html << "</script>"
      elsif args[:type] == :numeric
        attr[:type] = :text
        attr[:value] = value
        html << "<input#{self.attr_html(attr)} />"
      else
        attr[:value] = value
        html << "<input#{self.attr_html(attr)} />"
      end
      
      html << "</div></td></tr>"
    end
    
    html << "<tr#{classes_tr_html}><td colspan=\"2\" class=\"tdd\">#{args[:descr]}</td></tr>" if args[:descr]
    return html
  end
  
  def self.opts(opthash, curvalue = nil, opts_args = {})
    opts_args = {} if !opts_args
    Knj::ArrayExt.hash_sym(opts_args)
    
    return "" if !opthash
    cname = curvalue.class.name
    curvalue = curvalue.id if (cname == "Knj::Db_row" or cname == "Knj::Datarow")
    
    html = ""
    addsel = " selected=\"selected\"" if !curvalue
    
    html << "<option#{addsel} value=\"\">#{_("Add new")}</option>" if opts_args and (opts_args[:add] or opts_args[:addnew])
    html << "<option#{addsel} value=\"\">#{_("Choose")}</option>" if opts_args and opts_args[:choose]
    html << "<option#{addsel} value=\"\">#{_("None")}</option>" if opts_args and opts_args[:none]
    html << "<option#{addsel} value=\"\">#{_("All")}</option>" if opts_args and opts_args[:all]
    
    if opthash.is_a?(Hash) or opthash.class.to_s == "Dictionary"
      opthash.each do |key, value|
        html << "<option"
        sel = false
        
        if curvalue.is_a?(Array) and curvalue.index(key) != nil
          sel = true
        elsif curvalue.to_s == key.to_s
          sel = true
        elsif curvalue and curvalue.respond_to?(:is_knj?) and curvalue.id.to_s == key.to_s
          sel = true
        end
        
        html << " selected=\"selected\"" if sel
        html << " value=\"#{Knj::Web.html(key)}\">#{Knj::Web.html(value)}</option>"
      end
    elsif opthash.is_a?(Array)
      opthash.each_index do |key|
        if opthash[key.to_i] != nil
          html << "<option"
          html << " selected=\"selected\"" if curvalue.to_s == key.to_s
          html << " value=\"#{Knj::Web.html(key)}\">#{Knj::Web.html(opthash[key])}</option>"
        end
      end
    end
    
    return html
  end
  
  def self.rendering_engine(servervar = nil)
    servervar = _server if !servervar
    if !servervar
      raise "Could not figure out meta data."
    end
    
    agent = servervar["HTTP_USER_AGENT"].to_s.downcase
    
    if agent.include?("webkit") != nil
      return "webkit"
    elsif agent.include?("gecko") != nil
      return "gecko"
    elsif agent.include?("msie") != nil
      return "msie"
    elsif agent.include?("w3c") != nil or agent.include?("baiduspider") != nil or agent.include?("googlebot") != nil or agent.include?("bot") != nil
      return "bot"
    else
      #print "Unknown agent: #{agent}"
      return false
    end
  end
  
  def self.os(servervar = nil)
    servervar = _server if !servervar
    if !servervar
      raise "Could not figure out meta data."
    end
    
    agent = servervar["HTTP_USER_AGENT"].to_s.downcase
    
    if agent.include?("(windows;") != nil or agent.include?("windows nt") != nil
      return {
        "os" => "win",
        "title" => "Windows"
      }
    elsif agent.include?("linux") != nil
      return {
        "os" => "linux",
        "title" => "Linux"
      }
    end
    
    raise "Unknown OS: #{agent}"
  end
  
  #Returns various information about the current browser. Currently only works with the Hayabusa-project.
  def self.browser(servervar = nil)
    servervar = _server if !servervar
    raise "Could not figure out meta data." if !servervar
    agent = servervar["HTTP_USER_AGENT"].to_s.downcase
    
    if match = agent.include?("knj:true")
      browser = "bot"
      title = "Bot"
      version = "KnjHttp"
    elsif match = agent.match(/chrome\/(\d+\.\d+)/)
      browser = "chrome"
      title = "Google Chrome"
      version = match[1]
    elsif match = agent.match(/firefox\/(\d+\.\d+)/)
      browser = "firefox"
      title = "Mozilla Firefox"
      version = match[1]
    elsif servervar["HTTP_ACCEPT"] == "*/*" and servervar["HTTP_ACCEPT_LANGUAGE"] == "zh-cn,zh-hk,zh-tw,en-us" and servervar["HTTP_USER_AGENT"] == "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)" and (servervar["REMOTE_ADDR"][0,10] == "114.80.93." or servervar["HTTP_X_FORWARDED_FOR"][0,10] == "114.80.93.")
      browser = "bot"
      title = "bot"
      version = "(unknown annoying bot from China)"
    elsif match = agent.match(/msie\s*(\d+\.\d+)/)
      browser = "ie"
      title = "Microsoft Internet Explorer"
      version = match[1]
    elsif match = agent.match(/opera\/([\d+\.]+)/)
      browser = "opera"
      title = "Opera"
      version = match[1]
    elsif match = agent.match(/wget\/([\d+\.]+)/)
      browser = "bot"
      title = "Bot"
      version = "Wget #{match[1]}"
    elsif agent.include?("baiduspider")
      browser = "bot"
      title = "Bot"
      version = "Baiduspider"
    elsif agent.include?("googlebot")
      browser = "bot"
      title = "Bot"
      version = "Googlebot"
    elsif agent.include?("gidbot")
      browser = "bot"
      title = "Bot"
      version = "GIDBot"
    elsif match = agent.match(/android\s+([\d\.]+)/)
      browser = "android"
      title = "Android"
      version = match[1]
    elsif match = agent.match(/safari\/(\d+)/)
      browser = "safari"
      title = "Safari"
      version = match[1]
    elsif agent.include?("iPad")
      browser = "safari"
      title = "Safari (iPad)"
      version = "ipad"
    elsif agent.include?("bingbot")
      browser = "bot"
      title = "Bot"
      version = "Bingbot"
    elsif agent.include?("yahoo! slurp")
      browser = "bot"
      title = "Bot"
      version = "Yahoo! Slurp"
    elsif agent.include?("hostharvest")
      browser = "bot"
      title = "Bot"
      version = "HostHarvest"
    elsif agent.include?("exabot")
      browser = "bot"
      title = "Bot"
      version = "Exabot"
    elsif agent.include?("dotbot")
      browser = "bot"
      title = "Bot"
      version = "DotBot"
    elsif agent.include?("msnbot")
      browser = "bot"
      title = "Bot"
      version = "MSN bot"
    elsif agent.include?("yandexbot")
      browser = "bot"
      title = "Bot"
      version = "Yandex Bot"
    elsif agent.include?("mj12bot")
      browser = "bot"
      title = "Bot"
      version = "Majestic12 Bot"
    elsif agent.include?("facebookexternalhit")
      browser = "bot"
      title = "Bot"
      version = "Facebook Externalhit"
    elsif agent.include?("sitebot")
      browser = "bot"
      title = "Bot"
      version = "SiteBot"
    elsif match = agent.match(/java\/([\d\.]+)/)
      browser = "bot"
      title = "Java"
      version = match[1]
    elsif match = agent.match(/ezooms\/([\d\.]+)/)
      browser = "bot"
      title = "Ezooms"
      version = match[1]
    elsif match = agent.match(/ahrefsbot\/([\d\.]+)/)
      browser = "bot"
      title = "AhrefsBot"
      version = match[1]
    elsif agent.include?("sosospider")
      browser = "bot"
      title = "Bot"
      version = "Sosospider"
    else
      browser = "unknown"
      title = "(unknown browser)"
      version = "(unknown version)"
    end
    
    os = nil
    os_version = nil
    if agent.include?("linux") != nil
      os = "linux"
    elsif match = agent.match(/mac\s+os\s+x\s+([\d_+])/)
      os = "mac"
    elsif match = agent.match(/windows\s+nt\s+([\d\.]+)/)
      os = "windows"
      
      if match[1] == "5.1"
        os_version = "xp"
      end
    end
    
    return {
      "browser" => browser,
      "title" => title,
      "version" => version,
      "os" => os,
      "os_version" => os_version
    }
  end
  
  def self.locale(args = {})
    if args[:servervar]
      servervar = args[:servervar]
    else
      servervar = _server
    end
    
    if !servervar
      raise "Could not figure out meta data."
    end
    
    ret = {
      :recommended => [],
      :browser => []
    }
    
    alangs = servervar["HTTP_ACCEPT_LANGUAGE"].to_s
    if alangs.length > 0
      alangs.split(/\s*,\s*/).each do |alang|
        if qmatch = alang.match(/;\s*q=([\d\.]+)/)
          alang.gsub!(/;\s*q=([\d\.]+)/, "")
          q = qmatch[1].to_f
        else
          q = 1.0
        end
        
        if match = alang.match(/^([A-z]+)-([A-z]+)$/)
          locale = match[1]
          sublocale = match[2]
        else
          locale = alang
          sublocale = false
        end
        
        ret[:browser] << {
          :locale => locale,
          :sublocale => sublocale,
          :q => q
        }
      end
    end
    
    if args[:supported] and ret[:browser]
      ret[:browser].each do |locale|
        args[:supported].each do |supported_locale|
          if match = supported_locale.match(/^([A-z]+)_([A-z]+)$/)
            if match[1] == locale[:locale]
              if !locale[:sublocale]
                ret[:recommended] << supported_locale if ret[:recommended].index(supported_locale) == nil
              elsif locale[:sublocale] == match[1]
                ret[:recommended] << supported_locale if ret[:recommended].index(supported_locale) == nil
              end
            end
          end
        end
      end
    end
    
    if args[:default]
      ret[:recommended] << args[:default] if ret[:recommended].index(args[:default]) == nil
    end
    
    return ret
  end
  
  def self.hiddens(hidden_arr)
    html = ""
    
    hidden_arr.each do |hidden_hash|
      if hidden_hash.is_a?(Array)
        hidden_hash = {
          :name => hidden_hash[0],
          :value => hidden_hash[1]
        }
      else
        if hidden_hash[:value].is_a?(Array)
          if !hidden_hash[:value][0]
            hidden_hash[:value] = nil
          else
            key = hidden_hash[:value][1]
            obj = hidden_hash[:value][0]
            hidden_hash[:value] = obj[key]
          end
        end
      end
      
      html << "<input type=\"hidden\" name=\"#{hidden_hash[:name].to_s.html}\" value=\"#{hidden_hash[:value].to_s.html}\" />"
    end
    
    return html
  end
  
  #Parses a string to be safe for use in <a href="">.
  def self.ahref_parse(str)
    return str.to_s.gsub("&", "&amp;")
  end
  
  #URL-encodes a string.
  def self.urlenc(string)
    #Thanks to CGI framework
    string.to_s.gsub(/([^ a-zA-Z0-9_.-]+)/) do
      '%' + $1.unpack('H2' * $1.bytesize).join('%').upcase
    end.tr(' ', '+')
  end
  
  #URL-decodes a string.
  def self.urldec(string)
    #Thanks to CGI framework
    str = string.to_s.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/) do
      [$1.delete('%')].pack('H*')
    end
  end
  
  #Escapes HTML-characters in a string.
  def self.html(string)
    return string.to_s.gsub(/&/, "&amp;").gsub(/\"/, "&quot;").gsub(/>/, "&gt;").gsub(/</, "&lt;")
  end
  
  def self.html_args(h)
    str = ""
    h.each do |key, val|
      str << "&#{Php4r.urlencode(key)}=#{Php4r.urlencode(val)}"
    end
    
    return str
  end
  
  #Calculates the URL from meta hash.
  def self.url(args = {})
    if args[:meta]
      meta = args[:meta]
    else
      meta = _meta
    end
    
    url = ""
    
    if meta["HTTP_SSL_ENABLED"] == "1"
      url << "https://"
    else
      url << "http://"
    end
    
    url << meta["HTTP_HOST"]
    url << meta["REQUEST_URI"] if !args.key?(:uri) or args[:uri]
    
    return url
  end
  
  URL_SAFE_REPLACES = {
    "ø" => "oe",
    "æ" => "ae",
    "å" => "aa",
    /\s+/ => "_",
    "ö" => "oe"
  }
  def self.url_safe(str)
    str = str.to_s.downcase
    
    URL_SAFE_REPLACES.each do |key, val|
      str.gsub!(key, val)
    end
    
    return Knj::Strings.remove_non_ascii(str)
  end
end

class String
  def html
    return Knj::Web.html(self)
  end
  
  def sql
    begin
      return _db.escape(self)
    rescue NameError
      #ignore - not i KnjAppServer HTTP-session.
    end
    
    raise "Could not figure out where to find db object."
  end
end

class Symbol
  def html
    return self.to_s.html
  end
  
  def sql
    return self.to_s.sql
  end
end

class Fixnum
  def sql
    return self.to_s.sql
  end
  
  def html
    return self.to_s.html
  end
end
