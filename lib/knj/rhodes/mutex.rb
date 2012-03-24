class Mutex
  def synchronize
    sleep 0.05 while @working
    @working = true
    
    begin
      yield
    ensure
      @working = false
    end
  end
end