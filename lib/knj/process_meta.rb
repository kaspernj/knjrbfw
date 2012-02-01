require "#{$knjpath}/process"

class Knj::Process_meta
  attr_reader :process
  
  def initialize(args = {})
    @args = args
    @objects = {}
    
    exec_path = Knj::Os.executed_executable
    exec_file = "#{File.dirname(__FILE__)}/scripts/process_meta_exec.rb"
    
    @stdin, @stdout, @stderr, @wait_thr = Open3.popen3("#{exec_path} #{exec_file}")
    
    @process = Knj::Process.new(
      :out => @stdin,
      :in => @stdout,
      :err => @stderr,
      :listen => true,
      :debug => false,
      :on_err => proc{|line|
        $stderr.print "stderr: #{line}"
      }
    )
  end
  
  def spawn_object(class_name, var_name, *args)
    res = @process.send(
      "type" => "spawn_object",
      "class_name" => class_name,
      "var_name" => var_name,
      "args" => args
    )
    
    proxy_obj = Knj::Process_meta::Proxy_obj.new(:process_meta => self, :name => var_name)
  end
  
  def call_object(var_name, method_name, *args)
    res = @process.send(
      "type" => "call_object",
      "var_name" => var_name,
      "method_name" => method_name,
      "args" => args
    )
    
    return res["result"] if res.is_a?(Hash) and res["type"] == "call_object_success"
    raise "Unknown result: '#{Knj::Php.print_r(res, true)}'."
  end
  
  def destroy
    @process.send("type" => "exit")
    @err_thread.kill if @err_thread
    @process.destroy
  end
end

#This proxies all events to the sub-process.
class Knj::Process_meta::Proxy_obj
  #Overwrite internal methods some truly simulate the sub-process-methods.
  proxy_methods = ["to_s"]
  proxy_methods.each do |method_name|
    define_method(method_name) do |*args|
      return self.method_missing(method_name, *args)
    end
  end
  
  def initialize(args)
    @args = args
  end
  
  #This proxies all method-calls through the process-handeler and returns the result as the object was precent inside the current process-memory, even though it is not.
  def method_missing(method_name, *args)
    @args[:process_meta].call_object(@args[:name], method_name, *args)
  end
  
  def process_eval_unset
    @args[:process_meta].process.send("type" => "unset", "var_name" => @args[:name])
  end
end