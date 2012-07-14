#Currently broken - cannot get iotop to return values when running through script :-(
class Knj::Iotop
  def initialize(args)
    @data = {}
    @mutex = Monitor.new
    
    cmd = "iotop -bPk"
    
    if args[:pids]
      args[:pids].each do |pid|
        cmd << " --pid=#{pid.to_i}"
      end
    end
    
    @stdout = IO.popen(cmd)
    
    @thread = Knj::Thread.new do
      @stdout.each_line do |line_str|
        if line_str.match(/^Total\s+disk\s+read:\s+([\d\.]+)\s+(K\/s)\s+\|\s+Total\s+disk\s+write:\s+([\d\.]+)\s+(K\/s)\s*$/i)
          #ignore.
        elsif line_str.match(/  PID  PRIO  USER     DISK READ  DISK WRITE  SWAPIN      IO    COMMAND/)
          #ignore.
        elsif match = line_str.match(/^\s*(\d+)\s+(.+?)\s+(.+?)\s+([\d\.]+)\s+(K\/s)\s+([\d\.]+)\s+(K\/s)\s+([\d\.]+)\s+(%)\s+([\d\.]+)\s+(%)\s+(.+)\s*$/)
          @mutex.synchronize do
            pid = match[1].to_i
            
            if match[12].index("bestseller") != nil
              print line_str + "\n"
              Knj::Php.print_r(match)
            end
            
            @data[pid] = {
              :pid => pid,
              :prio => match[2],
              :user => match[3],
              :disk_read => (match[4].to_f * 1024).to_i,
              :disk_write => (match[6].to_f * 1024).to_i,
              :spawpin => match[8].to_f,
              :io => match[10].to_f,
              :cmd => match[12]
            }
          end
        else
          raise "Could not parse line: '#{line_str}'."
        end
      end
    end
  end
  
  #Returns information for the given PID.
  def [](pid)
    @mutex.synchronize do
      pid = pid.to_i
      raise "No such PID: '#{pid}'." if !@data.key?(pid)
      return @data[pid]
    end
  end
end