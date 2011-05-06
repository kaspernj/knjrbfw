require "knj/autoload"

class Appserver_cli
	def self.loadfile(filepath)
		require filepath
	end
	
	def self._(str)
		return str
	end
	
	def self.gettext
		return self
	end
	
	def self.lang_opts
		return []
	end
end

def _kas
	return Appserver_cli
end

def _db
	return $db
end

require "../include/autoinclude.rb"