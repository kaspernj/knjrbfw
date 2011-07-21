class Mutex
  def synchronize
    sleep 0.1 if @working
    @working = true
    begin
      yield
    ensure
      @working = false
    end
  end
end