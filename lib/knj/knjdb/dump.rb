#This class can be used to make SQL-dumps of databases, tables or however you want it.
class Knj::Db::Dump
  def initialize(args)
    @args = args
  end
  
  #Dumps all tables into the given IO.
  def dump(io)
    @args[:db].tables do |table|
      self.dump_table(io, table)
    end
  end
  
  #Dumps the given table into the given IO.
  def dump_table(io, table_obj)
    sqls = @args[:db].tables.create(table_obj.name, table_obj.data, :return_sql => true)
    sqls.each do |sql|
      io.write("#{sql};\n")
    end
    
    rows = []
    @args[:db].select(table_obj.name) do |row|
      rows << row
      self.dump_insert_multi(io, rows) if rows.length >= 1000
    end
    
    self.dump_insert_multi(io, rows) if !rows.empty?
  end
  
  #Dumps the given rows from the given table into the given IO.
  def dump_insert_multi(io, table_obj, rows)
    sql = @args[:db].insert_multi(table_obj.name, rows)
    io.write("#{sql};\n")
  end
end