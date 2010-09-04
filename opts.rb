module Knj
	module Opts
		$knjoptions = {
			"table" => "options"
		}
		
		def self.init(arr_opts)
			arr_opts.each do |pair|
				if (pair[0] == "knjdb" or pair[0] == "table")
					$knjoptions[pair[0]] = pair[1]
				end
			end
		end
		
		def self.get(title)
			db = $knjoptions["knjdb"]
			value = db.select($knjoptions["table"], {"title" => title}, {"limit" => 1}).fetch
			
			if !value
				return ""
			else
				return value["value"]
			end
		end
		
		def self.set(title, value)
			db = $knjoptions["knjdb"]
			result = db.select($knjoptions["table"], {"title" => title}, {"limit" => 1}).fetch
			
			if result.class.to_s == "NilClass"
				db.insert($knjoptions["table"], {
					"title" => title,
					"value" => value
				})
			else
				db.update($knjoptions["table"], {"value" => value}, {"id" => result["id"]})
			end
		end
	end
end