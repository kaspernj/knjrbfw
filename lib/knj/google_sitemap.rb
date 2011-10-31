class Knj::Google_sitemap
	attr_reader :doc
	
	def initialize(args = {})
    @args = args
    
		#used for Time.iso8601.
		require "time"
		
		@doc = REXML::Document.new
		@doc << REXML::XMLDecl.new("1.0", "UTF-8")
		
		@urlset = @doc.add_element("urlset")
		@urlset.add_attributes("xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9")
	end
	
	def add_url(url_value, lastmod_value, cf_value = nil, priority_value = nil)
		el = REXML::Element.new("url")
		
		loc = el.add_element("loc")
		loc.text = url_value
		
		if !lastmod_value or lastmod_value.to_i == 0
			raise sprintf("Invalid date: %1$s, url: %2$s", lastmod_value.to_s, url_value)
		end
		
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