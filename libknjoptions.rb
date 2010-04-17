$knjoptions = {
	"table" => "options"
}

def opt_setOpts(arr_opts)
	arr_opts.each do |pair|
		if (pair[0] == "knjdb" or pair[0] == "table")
			$knjoptions[pair[0]] = pair[1]
		end
	end
end

def opt_get(title)
	db = $knjoptions["knjdb"]
	value = db.select($knjoptions["table"], {"title" => title}, {"limit" => "1"}).fetch
	
	if (!value)
		return ""
	else
		return value["value"]
	end
end

def opt_set(title, value)
	db = $knjoptions["knjdb"]
	result = db.select($knjoptions["table"], {"title" => title}, {"limit" => "1"}).fetch
	
	if (result.class.to_s == "NilClass")
		db.insert($knjoptions["table"], {
				"title" => title,
				"value" => value
			}
		)
	else
		db.update($knjoptions["table"], {
				"value" => value
			},
			{"id" => result["id"]}
		)
	end
end

module Knj
	class Opts
		def self.init(paras)
			opt_setOpts(paras)
		end
		
		def self.get(title)
			return opt_get(title)
		end
		
		def self.set(title, value)
			return opt_set(title, value)
		end
	end
end