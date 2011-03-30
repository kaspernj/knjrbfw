class KnjDB_sqlite3::Indexes
	def initialize(args)
		@args = args
	end
end

class KnjDB_sqlite3::Indexes::Index
	def initialize(args)
		@args = args
	end
	
	def name
		return @args[:data][:name]
	end
	
	def drop
		@args[:db].query("DROP INDEX `#{self.name}`")
	end
end