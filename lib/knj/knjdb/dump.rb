#This class can be used to make SQL-dumps of databases, tables or however you want it.
class Knj::Db::Dump
  #Constructor.
  #===Examples
  # dump = Knj::Db::Dump.new(:db => db)
  def initialize(args)
    @args = args
    @debug = @args[:debug]
  end
  
  #Dumps all tables into the given IO.
  def dump(io)
    print "Going through tables.\n" if @debug
    
    @args[:db].tables.list do |table|
      print "Dumping table: '#{table.name}'.\n" if @debug
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
      self.dump_insert_multi(io, table_obj, rows) if rows.length >= 1000
    end
    
    self.dump_insert_multi(io, table_obj, rows) if !rows.empty?
  end
  
  #Dumps the given rows from the given table into the given IO.
  def dump_insert_multi(io, table_obj, rows)
    print "Inserting #{rows.length} into #{table_obj.name}.\n" if @debug
    sqls = @args[:db].insert_multi(table_obj.name, rows, :return_sql => true)
    sqls.each do |sql|
      io.write("#{sql};\n")
    end
    
    rows.clear
  end
end