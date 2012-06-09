#This class can manipulate the CPU behavior through "cpufreq".
class Knj::Cpufreq
  #Data that is used to identify the CPU controlled by this object.
  attr_reader :data
  
  #Useually called through "Knj::Cpufreq.list".
  def initialize(data)
    @data = data
    @allowed_govs = ["performance", "ondemand", "powersafe", "conservative"]
  end
  
  #Returns a list of CPUs.
  #===Examples
  # list = Knj::Cpufreq.list
  # list.each do |cpufreq|
  #   cpufreq.governor = "performance"
  # end
  def self.list
    ret = []
    cont = File.read("/proc/cpuinfo")
    
    matches = cont.scan(/processor\s*:[\s\S]+?\n\n/)
    raise "Could not detect CPUs" if !matches or matches.empty?
    
    matches.each do |cpucont|
      cpu_features = {}
      features = cpucont.scan(/(.+)\s*:\s*(.+)\s*/)
      
      features.each do |data|
        cpu_features[data[0].strip] = data[1].strip
      end
      
      ret << Knj::Cpufreq.new(cpu_features)
    end
    
    return ret
  end
  
  #Sets the governor.
  #===Examples
  # cpufreq.governor = "performance"
  def governor=(newgov)
    raise "Governor not found." if @allowed_govs.index(newgov) == nil
    
    cmd = "cpufreq-set --cpu #{@data["processor"]} --governor #{newgov}"
    res = Knj::Os::shellcmd(cmd)
    if res.index("Error setting new values") != nil
      raise res.strip
    end
  end
end