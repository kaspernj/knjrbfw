class Knj::Google_sitemap
	attr_reader :doc
	
	def initialize
		@doc = REXML::Document.new
		@doc << REXML::XMLDecl.new("1.0", "UTF-8")
		
		@urlset = @doc.add_element("urlset")
		@urlset.add_attributes("xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9")
	end
	
	def add_url(url_value, lastmod_value, cf_value = nil, priority_value = nil)
		el = REXML::Element.new("url")
		
		loc = el.add_element("loc")
		loc.text = url_value
		
		lm = el.add_element("lastmod")
		lm.text = lastmod_value
		
		cf = el.add_element("changefreq")
		cf.text = cf_value
		
		priority = el.add_element("priority")
		priority.text = priority_value
		
		@doc.root << el
	end
	
	def to_xml
		return @doc.to_s
	end
	
	def to_s
		return @doc.to_s
	end
	
	def write
		writer = REXML::Formatters::Pretty.new(5)
		writer.write(@doc, $stdout)
	end
end