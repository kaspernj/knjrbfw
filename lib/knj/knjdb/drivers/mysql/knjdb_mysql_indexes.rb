class KnjDB_mysql::Indexes
  def initialize(args)
    @args = args
  end
end

class KnjDB_mysql::Indexes::Index
  attr_reader :columns
  
  def initialize(args)
    @args = args
    @columns = []
  end
  
  def name
    return @args[:data][:Key_name]
  end
  
  def drop
    sql = "DROP INDEX `#{self.name}` ON `#{@args[:table].name}`"
    @args[:db].query(sql)
  end
  
  def data
    return {
      "name" => name,
      "columns" => @columns
    }
  end
end