class Knj::Rhodes
	def self.html_links(args)
		html_cont = "#{args[:html]}"
		
		html_cont.scan(/(<a([^>]+)href=\"(http.+?)\")/) do |match|
			html_cont = html_cont.gsub(match[0], "<a#{match[1]}href=\"javascript: knj_rhodes_html_links({url: '#{match[2]}'});\"")
		end
		
		return html_cont
	end
end