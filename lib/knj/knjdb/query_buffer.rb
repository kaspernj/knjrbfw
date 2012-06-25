#This class buffers a lot of queries and flushes them out via transactions.
class Knj::Db::Query_buffer
  #Constructor. Takes arguments to be used and a block.
  def initialize(args)
    @args = args
    @queries = []
    @debug = @args[:debug]
    
    begin
      yield(self)
    ensure
      self.flush if !@queries.empty?
    end
  end
  
  #Adds a query to the buffer.
  def query(str)
    STDOUT.print "Adding to buffer: #{str}\n" if @debug
    @queries << str
    self.flush if @queries.length > 1000
    return nil
  end
  
  #Delete as on a normal Knj::Db.
  def delete(table, where)
    self.query(@args[:db].delete(table, where, :return_sql => true))
    return nil
  end
  
  #Flushes all queries out in a transaction.
  def flush
    return nil if @queries.empty?
    
    @args[:db].transaction do
      @queries.shift(1000).each do |str|
        STDOUT.print "Executing via buffer: #{str}\n" if @debug
        @args[:db].q(str)
      end
    end
    
    return nil
  end
end