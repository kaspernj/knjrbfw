class KnjDB_sqlite3::Indexes
  def initialize(args)
    @args = args
  end
end

class KnjDB_sqlite3::Indexes::Index
  attr_reader :columns
  
  def initialize(args)
    @args = args
    @columns = []
  end
  
  def name
    return @args[:data][:name]
  end
  
  def drop
    @args[:db].query("DROP INDEX `#{self.name}`")
  end
  
  def data
    return {
      "name" => name,
      "columns" => @columns
    }
  end
end