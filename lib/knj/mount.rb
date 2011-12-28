class Knj::Mount
  def self.list(args = {})
    mount_output = Knj::Os.shellcmd("mount")
    ret = []
    
    mount_output.scan(/^(.+?) on (.+?) type (.+) \((.+?)\)$/) do |match|
      type = match[2]
      folder_from = match[0]
      folder_to = match[1]
      opts = match[3].split(",")
      
      folder_from = nil if folder_from == "none"
      #raise "The folder doesnt exist?" if !File.exists?(folder_to)
      
      add = true
      add = false if args.key?("to") and args["to"] != folder_to
      add = false if args.key?("from") and args["from"] != folder_from
      
      if args["from_search"]
        Knj::Strings.searchstring(args["from_search"]).each do |str|
          add = false if !folder_from or folder_from.index(str) == nil
        end
      end
      
      if args["to_search"]
        Knj::Strings.searchstring(args["to_search"]).each do |str|
          add = false if !folder_to or folder_to.index(str) == nil
        end
      end
      
      if add
        ret << Knj::Mount.new(
          :type => type,
          :from => folder_from,
          :to => folder_to,
          :opts => opts
        )
      end
    end
    
    return ret
  end
  
  def self.mount(args)
    cmd = "mount"
    cmd += " -t #{Knj::Strings.unixsafe(args["type"])}" if args.key?("type")
    cmd += " --bind" if args["bind"]
    cmd += " #{Knj::Strings.unixsafe(args["from"])} #{Knj::Strings.unixsafe(args["to"])}"
    
    if args.key?("opts")
      raise "opts argument must be an array." if !args["opts"].is_a?(Array)
      
      cmd += "-O "
      
      first = true
      args["opts"].each do |opt|
        cmd += "," if !first
        first = false if first
        
        if opt.is_a?(Array)
          raise "Array-opt must have a length of 2." if opt.length != 2
          cmd += "#{Knj::Strings.unixsafe(opt[0])}=#{Knj::Strings.unixsafe(opt[1])}"
        elsif arg.is_a?(String)
          cmd += "#{Knj::Strings.unixsafe(opt)}"
        else
          raise "Unknown class: #{opt.class.name}."
        end
      end
    end
    
    Knj::Os.shellcmd(cmd)
  end
  
  def self.ensure(args)
    list = Knj::Mount.list("to_search" => args["to"])
    return false if !list.empty?
    Knj::Mount.mount(args)
    return true
  end
  
  attr_reader :data
  
  def initialize(data)
    @data = data
  end
  
  def [](key)
    raise "Invalid key: #{key}." if !@data.key?(key)
    return @data[key]
  end
  
  def unmount
    Knj::Os.shellcmd("umount #{Knj::Strings.unixsafe(@data[:to])}")
  end
  
  alias :umount :unmount
  
  def access?(args = {})
    args["timeout"] = 2 if !args.key?("timeout")
    access = false
    
    begin
      Timeout.timeout(args["timeout"]) do
        Dir.new(@data[:to]).each do |file|
          access = true
          break
        end
      end
    rescue Timeout::Error => e
      return false
    end
    
    return access
  end
end
