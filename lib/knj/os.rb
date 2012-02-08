module Knj::Os
  def self.homedir
    if ENV["USERPROFILE"]
      homedir = ENV["USERPROFILE"]
    else
      homedir = File.expand_path("~")
    end
    
    if homedir.length <= 0
      raise "Could not figure out the homedir."
    end
    
    return homedir
  end
  
  def self.whoami
    if ENV["USERNAME"]
      whoami = ENV["USERNAME"]
    else
      whoami = %x[whoami].strip
    end
    
    if whoami.length <= 0
      raise "Could not figure out the user who is logged in."
    end
    
    return whoami
  end
  
  def self.os
    if ENV["OS"]
      teststring = ENV["OS"].to_s
    elsif (RUBY_PLATFORM)
      teststring = RUBY_PLATFORM.to_s
    end
    
    if teststring.downcase.index("windows") != nil
      return "windows"
    elsif teststring.downcase.index("linux") != nil
      return "linux"
    else
      raise "Could not figure out OS."
    end
  end
  
  def self.mode
    raise "stub!"
  end
  
  def self.class_exist(classstr)
    if Module.constants.index(classstr) != nil
      return true
    end
    
    return false
  end
  
  def self.chdir_file(filepath)
    if File.symlink?(filepath)
      Dir.chdir(File.dirname(File.readlink(filepath)))
    else
      Dir.chdir(File.dirname(filepath))
    end
  end
  
  def self.realpath(path)
    if File.symlink?(path)
      return self.realpath(File.readlink(path))
    end
    
    return path
  end
  
  #Runs a command and returns output. Also throws an exception of something is outputted to stderr.
  def self.shellcmd(cmd)
    res = {
      :out => "",
      :err => ""
    }
    
    Open3.popen3(cmd) do |stdin, stdout, stderr|
      res[:out] << stdout.read
      res[:err] << stderr.read
    end
    
    if res[:err].to_s.strip.length > 0
      raise res[:err]
    end
    
    return res[:out]
  end
  
  #Runs a command as a process of its own and wont block or be depended on this process.
  def self.subproc(cmd)
    cmd = cmd.to_s + "  >> /dev/null 2>&1 &"
    %x[#{cmd}]
  end
  
  #Returns the xauth file for GDM.
  def self.xauth_file
    authfile = ""
    
    if File.exists?("/var/run/gdm")
      Dir.foreach("/var/run/gdm") do |file|
        next if file == "." or file == ".." or !file.match(/^auth-for-gdm-.+$/)
        authfile = "/var/run/gdm/#{file}/database"
      end
    end
    
    if File.exists?("/var/run/lightdm")
      Dir.foreach("/var/run/lightdm") do |file|
        next if file == "." or file == ".."
        
        Dir.foreach("/var/run/lightdm/#{file}") do |f2|
          authfile = "/var/run/lightdm/#{file}/#{f2}" if f2.match(/^:(\d+)$/)
        end
      end
    end
    
    if authfile.to_s.length <= 0
      raise "Could not figure out authfile for GDM."
    end
    
    return authfile
  end
  
  #Checks if the display variable and xauth is set - if not sets it to the GDM xauth and defaults the display to :0.0.
  def self.check_display_env
    ret = {}
    
    if ENV["DISPLAY"].to_s.strip.length <= 0
      x_procs = Knj::Unix_proc.list("grep" => "/usr/bin/X")
      set_disp = nil
      
      x_procs.each do |x_proc|
        if match = x_proc["cmd"].match(/(:\d+)/)
          set_disp = match[1]
          break
        end
      end
      
      raise "Could not figure out display." if !set_disp
      
      ENV["DISPLAY"] = set_disp
      ret["display"] = set_disp
    else
      ret["display"] = ENV["DISPLAY"]
    end
    
    if !ENV["XAUTHORITY"]
      res = Knj::Os.xauth_file
      ENV["XAUTHORITY"] = res
      ret["xauth"] = res
    else
      ret["xauth"] = ENV["XAUTHORITY"]
    end
    
    return ret
  end
  
  #Returns the command used to execute the current process.
  def self.executed_cmd
    return ENV["SUDO_COMMAND"] if ENV["SUDO_COMMAND"]
    
    proc_self = Knj::Unix_proc.find_self
    cmd = proc_self["cmd"]
    
    cmd.gsub!(/^ruby([\d\.]+)/, ENV["_"]) if ENV["_"]
    
    return cmd
  end
  
  #Returns the Ruby executable that is running the current process if possible.
  def self.executed_executable
    return ENV["rvm_ruby_string"] if ENV["rvm_ruby_string"].to_s.length > 0
    raise "Could not figure out the executed executable."
  end
end