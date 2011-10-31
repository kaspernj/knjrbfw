class Knj::Mutexcl
  def initialize(args = {})
    @args = args
    raise "No ':modes' given in arguments." if !@args.key?(:modes)
    @mutex = Mutex.new
    @blocked = {}
    @args[:modes].each do |mode, data|
      data[:blocks].each do |block|
        @blocked[block] = {
          :mutex => Mutex.new,
          :count => 0
        }
      end
    end
  end
  
  def self.rw
    return Knj::Mutexcl.new(
      :modes => {
        :reader => {:blocks => [:writer]},
        :writer => {:blocks => [:writer, :reader]}
      }
    )
  end
  
  def sync(mode)
    raise "No such mode: '#{mode}'." if !@args[:modes].key?(mode)
    
    while @blocked[mode][:count].to_i > 0
      STDOUT.print "Sleeping because blocked '#{mode}' (#{@blocked[mode][:count]}).\n"
      sleep 0.1
    end
    
    @mutex.synchronize do
      @args[:modes][mode][:blocks].each do |block|
        @blocked[block][:count] += 1
      end
    end
    
    begin
      yield
    ensure
      @args[:modes][mode][:blocks].each do |block|
        @blocked[block][:count] -= 1
      end
    end
  end
end