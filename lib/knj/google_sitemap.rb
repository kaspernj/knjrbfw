class Knj::Google_sitemap
  attr_reader :doc
  
  def initialize(args = {})
    raise "No block given." if !block_given?
    
    @args = args
    
    #used for Time.iso8601.
    require "time"
    
    #REXML is known to leak memory - use subprocess.
    Knj.gem_require(:Ruby_process)
    @subproc = Ruby_process.new.spawn_process(:title => "google_sitemap", :debug_err => true)
    
    begin
      @subproc.static("Object", "require", "rexml/rexml")
      @subproc.static("Object", "require", "rexml/document")
      @subproc.static("Object", "require", "rexml/element")
      
      @doc = @subproc.new("REXML::Document")
      
      xmldecl = @subproc.new("REXML::XMLDecl", "1.0", "UTF-8")
      @doc << xmldecl
      
      urlset = @doc.add_element("urlset")
      urlset.add_attributes("xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9")
      
      @root = @doc.root
      
      Ruby_process::Cproxy.run do |data|
        @subproc = data[:subproc]
        yield(self)
      end
    ensure
      @doc = nil
      @root = nil
      @subproc = nil
    end
  end
  
  #Adds a URL to the XML.
  def add_url(url_value, lastmod_value, cf_value = nil, priority_value = nil)
    if !lastmod_value or lastmod_value.to_i == 0
      raise sprintf("Invalid date: %1$s, url: %2$s", lastmod_value.to_s, url_value)
    end
    
    el = @subproc.new("REXML::Element", "url")
    
    loc = el.add_element("loc")
    loc.text = url_value
    
    lm = el.add_element("lastmod")
    if @args.key?(:date_min) and @args[:date_min] > lastmod_value
      lastmod_value = @args[:date_min]
    end
    
    lm.text = lastmod_value.iso8601
    
    if cf_value
      cf = el.add_element("changefreq")
      cf.text = cf_value
    end
    
    if priority_value
      priority = el.add_element("priority")
      priority.text = priority_value
    end
    
    @root << el
  end
  
  #This will return a non-human-readable XML-string.
  def to_xml
    return @doc.to_s
  end
  
  #This will return a non-human-readable XML-string.
  def to_s
    return @doc.to_s
  end
  
  #This will print the result.
  def write
    #Require and spawn StringIO in the subprocess.
    @subproc.static("Object", "require", "stringio")
    string_io = @subproc.new("StringIO")
    
    #We want a human-readable print.
    writer = @subproc.new("REXML::Formatters::Pretty", 5)
    writer.write(@doc, string_io)
    
    #Prepare printing by rewinding StringIO to read from beginning.
    string_io.rewind
    
    #Print out the result in bits to avoid raping the memory (subprocess is already raped - no question there...).
    string_io.each(4096) do |str|
      print str
    end
  end
end