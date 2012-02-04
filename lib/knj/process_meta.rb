require "#{$knjpath}/process"

class Knj::Process_meta
  attr_reader :process
  
  def initialize(args = {})
    @args = args
    @objects = {}
    
    if @args["exec_path"]
      exec_path = @args["exec_path"]
    else
      exec_path = Knj::Os.executed_executable
    end
    
    exec_file = "#{File.dirname(__FILE__)}/scripts/process_meta_exec.rb"
    
    @stdin, @stdout, @stderr, @wait_thr = Open3.popen3("#{exec_path} #{exec_file}")
    
    args = {
      :out => @stdin,
      :in => @stdout,
      :listen => true,
      :debug => @args["debug"]
    }
    
    if @args["debug"] or @args["debug_err"]
      args[:err] = @stderr
      args[:on_err] = proc{|line|
        $stderr.print "stderr: #{line}"
      }
    end
    
    @process = Knj::Process.new(args)
  end
  
  #Executes a static method on a class in the sub-process.
  def static(const, method_name, *args, &block)
    res = @process.send(
      "obj" => {
        "type" => "static",
        "const" => const,
        "method_name" => method_name,
        "args" => args,
      },
      &block
    )
    
    return res["result"] if res["type"] == "call_const_success"
    raise "Unknown result: '#{Knj::Php.print_r(res, true)}'."
  end
  
  #Spawns a new object in the subprocess by that classname, with those arguments and with that block.
  def new(class_name, *args, &block)
    return self.spawn_object(class_name, nil, *args, &block)
  end
  
  #Spawns a new object in the subprocess and returns a proxy-variable for that subprocess-object.
  def spawn_object(class_name, var_name = nil, *args, &block)
    proxy_obj = Knj::Process_meta::Proxy_obj.new(:process_meta => self, :name => var_name)
    
    if var_name == nil
      var_name = proxy_obj.__id__
      proxy_obj._process_meta_args[:name] = var_name
    end
    
    res = @process.send(
      {
        "obj" => {
          "type" => "spawn_object",
          "class_name" => class_name,
          "var_name" => var_name,
          "args" => args
        }
      },
      &block
    )
    
    return proxy_obj
  end
  
  #Evaluates a string in the sub-process.
  def str_eval(str)
    res = @process.send("obj" => {
      "type" => "str_eval",
      "str" => str
    })
    
    return res["result"] if res.is_a?(Hash) and res["type"] == "call_eval_success"
    return "Unknown result: '#{Knj::Php.print_r(res, true)}'."
  end
  
  #Calls a method on an object and returns the result.
  def call_object(args, &block)
    res = @process.send(
      {
        "buffer_use" => args["buffer_use"],
        "obj" => {
          "type" => "call_object_block",
          "var_name" => args["var_name"],
          "method_name" => args["method_name"],
          "args" => args["args"]
        }
      },
      &block
    )
    
    return res["result"] if res.is_a?(Hash) and res["type"] == "call_object_success"
    raise "Unknown result: '#{Knj::Php.print_r(res, true)}'."
  end
  
  #Destroyes the project and unsets all variables on the Process_meta-object.
  def destroy
    begin
      @process.send("obj" => {"type" => "exit"})
    rescue Exception => e
      raise e if e.message != "exit"
    end
    
    @err_thread.kill if @err_thread
    @process.destroy
    Process.kill("TERM", @wait_thr.pid)
    
    @process = nil
    @wait_thr = nil
    @stdin = nil
    @stdout = nil
    @stderr = nil
    @objects = nil
    @args = nil
  end
end

#This proxies all events to the sub-process.
class Knj::Process_meta::Proxy_obj
  #Overwrite internal methods some truly simulate the sub-process-methods.
  proxy_methods = ["to_s", "respond_to?"]
  proxy_methods.each do |method_name|
    define_method(method_name) do |*args|
      return self.method_missing(method_name, *args)
    end
  end
  
  def initialize(args)
    @args = args
    @_process_meta_buffer_use = false
  end
  
  #This proxies all method-calls through the process-handeler and returns the result as the object was precent inside the current process-memory, even though it is not.
  def method_missing(method_name, *args, &block)
    @args[:process_meta].call_object(
      {
        "var_name" => @args[:name],
        "method_name" => method_name,
        "args" => args,
        "buffer_use" => @_process_meta_block_buffer_use
      },
      &block
    )
  end
  
  def _process_meta_unset
    @args[:process_meta].process.send("obj" => {"type" => "unset", "var_name" => @args[:name]})
  end
  
  def _process_meta_args
    return @args
  end
  
  def _process_meta_block_buffer_use=(newval)
    @_process_meta_block_buffer_use = newval
  end
end