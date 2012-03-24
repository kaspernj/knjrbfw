$knjautoload = false

class Knj::Rhodes
  attr_accessor :locale
  attr_reader :db, :ob, :gettext, :args
  
  def initialize(args = {})
    require "#{$knjpath}arrayext.rb"
    require "#{$knjpath}datet.rb"
    require "#{$knjpath}php.rb"
    require "#{$knjpath}objects.rb"
    require "#{$knjpath}datarow.rb"
    require "#{$knjpath}event_handler.rb"
    require "#{$knjpath}hash_methods.rb"
    require "#{$knjpath}errors.rb"
    require "#{$knjpath}gettext_threadded.rb"
    require "#{$knjpath}locales.rb"
    require "#{$knjpath}locale_strings.rb"
    require "#{$knjpath}web.rb"
    
    if !Kernel.const_defined?("Mutex")
      print "Mutex not defined - loading alternative.\n"
      require "#{$knjpath}rhodes/mutex.rb"
    end
    
    require "#{$knjpath}opts.rb"
    
    require "#{$knjpath}knjdb/libknjdb.rb"
    require "#{$knjpath}knjdb/revision.rb"
    require "#{$knjpath}knjdb/drivers/sqlite3/knjdb_sqlite3.rb"
    require "#{$knjpath}knjdb/drivers/sqlite3/knjdb_sqlite3_tables.rb"
    require "#{$knjpath}knjdb/drivers/sqlite3/knjdb_sqlite3_columns.rb"
    require "#{$knjpath}knjdb/drivers/sqlite3/knjdb_sqlite3_indexes.rb"
    
    @args = args
    @callbacks = {}
    @callbacks_count = 0
    
    @db = Knj::Db.new(
      :type => "sqlite3",
      :subtype => "rhodes",
      :path => "#{Rho::RhoApplication.get_base_app_path}app/rhodes_default.sqlite3",
      :return_keys => "symbols",
      :require => false
    )
    
    if @args[:schema]
      schema = @args[:schema]
    else
      schema = {"tables" => {}}
    end
    
    #Table used for options-module.
    schema["tables"]["Option"] = {
      "columns" => [
        {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
        {"name" => "title", "type" => "varchar"},
        {"name" => "value", "type" => "text"}
      ]
    }
    
    #Run database-revision.
    dbrev = Knj::Db::Revision.new
    dbrev.init_db("schema" => schema, "db" => @db)
    
    #Initialize options-module.
    Knj::Opts.init(
      "table" => "Option",
      "knjdb" => @db
    )
    
    #Initialize objects-module.
    @ob = Knj::Objects.new(
      :db => @db,
      :class_path => "#{Rho::RhoApplication.get_base_app_path}app/models",
      :require => false,
      :module => @args[:module],
      :datarow => true
    )
    
    #Initialize locales.
    @gettext = Knj::Gettext_threadded.new
    @gettext.load_dir("#{Rho::RhoApplication.get_base_app_path}app/locales")
    
    locale = "#{System.get_property("locale")}_#{System.get_property("country")}".downcase
    
    @args[:locale_default] = "en_GB" if !@args[:locale_default]
    
    langs = @gettext.langs.keys
    langs.each do |lang|
      if locale == lang.downcase
        @locale = lang
        break
      end
    end
    
    if !@locale
      langs.each do |lang|
        if locale.slice(0..2) == lang.downcase.slice(0..2)
          @locale = lang
          break
        end
      end
    end
    
    @locale = @args[:locale_default] if !@locale
  end
  
  def inputs(*arr)
    html = ""
    
    arr.each do |data|
      value = ""
      
      data[:type] = :text if !data.key?(:type)
      
      if data.key?(:value) and data[:value].is_a?(Array) and data[:value][0]
        value = data[:value][0][data[:value][1]]
      elsif data.key?(:valthread_callbackue)
        value = data[:value]
      end
      
      extra_args = ""
      extra_args = " autofocus=\"autofocus\"" if data[:autofocus]
      
      css = {}
      
      if data[:type] == :textarea
        css["height"] = data[:height] if data.key?(:height)
        
        html << "<div data-role=\"fieldcontain\">"
        html << "<label for=\"#{data[:name]}\">#{data[:title]}</label>"
        html << "<textarea name=\"#{data[:name]}\" id=\"#{data[:name]}\"#{Knj::Web.style_html(css)}#{extra_args}>#{value}</textarea>"
        html << "</div>"
      else
        html << "<div data-role=\"fieldcontain\">"
        html << "<label for=\"#{data[:name]}\">#{data[:title]}</label>"
        html << "<input type=\"#{data[:type]}\" name=\"#{data[:name]}\" id=\"#{data[:name]}\" value=\"#{value}\"#{Knj::Web.style_html(css)}#{extra_args} />"
        html << "</div>"
      end
    end
    
    return html
  end
  
  def self.html_links(args)
    html_cont = "#{args[:html]}"
    
    html_cont.scan(/(<a([^>]+)href=\"(http.+?)\")/) do |match|
      html_cont = html_cont.gsub(match[0], "<a#{match[1]}href=\"javascript: knj_rhodes_html_links({url: '#{match[2]}'});\"")
    end
    
    return html_cont
  end
  
  def _(str)
    return @gettext.trans(@locale, str.to_s)
  end
  
  def session_key(key)
    if key == :locale
      return @locale
    end
    
    raise "No such key: '#{key}'."
  end
  
  def callback(&block)
    count = @callbacks_count
    @callbacks_count += 1
    @callbacks[count] = block
    return count
  end
  
  def callbacks(key)
    block = @callbacks[key.to_i]
    raise "Block not found for key: '#{key}'." if !block
    @callbacks.delete(key.to_i)
    return block
  end
end

#This method is used to emulate web-behavior and make Knj::Locales.number_out and friends work properly.
def _session
  return {:locale => $rhodes.locale}
end

#This method is used to make gettext work.
def _(key)
  return $rhodes._(key)
end