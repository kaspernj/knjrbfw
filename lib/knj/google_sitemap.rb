class Knj::Google_sitemap
  attr_reader :doc
  
  def initialize(args = {})
    raise "No block given." if !block_given?
    
    @args = args
    
    #used for Time.iso8601.
    require "time"
    
    #REXML is known to leak memory - use subprocess.
    @subproc = Knj::Process_meta.new("id" => "google_sitemap", "debug_err" => true)
    
    begin
      @subproc.static("Object", "require", "rexml/rexml")
      @subproc.static("Object", "require", "rexml/document")
      
      @doc = @subproc.new("REXML::Document")
      
      xmldecl = @subproc.new("REXML::XMLDecl", "1.0", "UTF-8")
      @doc._pm_send_noret("<<", xmldecl)
      
      urlset = @subproc.proxy_from_call(@doc, "add_element", "urlset")
      urlset._pm_send_noret("add_attributes", {"xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9"})
      
      @root = @subproc.proxy_from_call(@doc, "root")
      yield(self)
    ensure
      @doc = nil
      @root = nil
      @subproc.destroy
      @subproc = nil
    end
  end
  
  def add_url(url_value, lastmod_value, cf_value = nil, priority_value = nil)
    if !lastmod_value or lastmod_value.to_i == 0
      raise sprintf("Invalid date: %1$s, url: %2$s", lastmod_value.to_s, url_value)
    end
    
    el = @subproc.new("REXML::Element", "url")
    
    loc = @subproc.proxy_from_call(el, "add_element", "loc")
    loc._pm_send_noret("text=", url_value)
    
    lm = @subproc.proxy_from_call(el, "add_element", "lastmod")
    if @args.key?(:date_min) and @args[:date_min] > lastmod_value
      lastmod_value = @args[:date_min]
    end
    
    lm._pm_send_noret("text=", lastmod_value.iso8601)
    
    if cf_value
      cf = @subproc.proxy_from_call(el, "add_element", "changefreq")
      cf._pm_send_noret("text=", cf_value)
    end
    
    if priority_value
      priority = @subproc.proxy_from_call("el", "add_element", "priority")
      priority._pm_send_noret("text=", priority_value)
    end
    
    @root._pm_send_noret("<<", el)
  end
  
  def to_xml
    return @doc.to_s
  end
  
  def to_s
    return @doc.to_s
  end
  
  def write
    @subproc.static("Object", "require", "stringio")
    string_io = @subproc.spawn_object("StringIO")
    
    writer = @subproc.spawn_object("REXML::Formatters::Pretty", 5)
    writer._pm_send_noret("write", @doc, string_io)
    
    print string_io.string
  end
end