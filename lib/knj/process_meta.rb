require "#{$knjpath}process"
require "#{$knjpath}os"

class Knj::Process_meta
  attr_reader :process, :pid
  
  def initialize(args = {})
    @args = args
    @objects = {}
    
    #These variables are used to free memory in the subprocess, by using ObjectSpace#define_finalizer. The Mutex is the avoid problems when writing to the finalize-array multithreadded.
    @finalize = []
    @finalize_mutex = Mutex.new
    
    if @args["exec_path"]
      exec_path = @args["exec_path"]
    else
      exec_path = Knj::Os.executed_executable
    end
    
    exec_file = "#{File.dirname(__FILE__)}/scripts/process_meta_exec.rb"
    
    if args["id"]
      id = args["id"]
    else
      id = caller[0].to_s.strip
    end
    
    cmd = "#{exec_path} \"#{exec_file}\" #{Knj::Strings.unixsafe(id)}"
    
    if RUBY_ENGINE == "jruby"
      pid, @stdin, @stdout, @stderr = IO.popen4("#{exec_path} --#{RUBY_VERSION[0, 3]} \"#{exec_file}\" \"#{id}\"")
    else
      @stdin, @stdout, @stderr = Open3.popen3(cmd)
    end
    
    @stdout.sync = true
    @stdin.sync = true
    
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
    
    #Wait for process to start and check that it is returning the expected output.
    start_line = @stdout.gets
    raise "Expected startline from process to be 'process_meta_started' but got: '#{start_line}'." if start_line != "process_meta_started\n"
    
    @process = Knj::Process.new(args)
    
    res = @process.send("obj" => {"type" => "process_data"})
    raise "Unexpected process-data: '#{res}'." if !res.is_a?(Hash) or res["type"] != "process_data_success"
    @pid = res["pid"]
    
    #If block is given then run block and destroy self.
    if block_given?
      begin
        yield(self)
      ensure
        self.destroy
      end
    end
  end
  
  def proxy_finalizer(id)
    @finalize_mutex.synchronize do
      @finalize << id
    end
  end
  
  def check_finalizers
    return nil if @finalize.empty?
    
    finalize = nil
    @finalize_mutex.synchronize do
      finalize = @finalize
      @finalize = []
    end
    
    begin
      @process.send("obj" => {
        "type" => "unset_multiple",
        "var_names" => finalize
      })
    rescue => e
      if e.message.to_s.index("Var-name didnt exist when trying to unset:")
        #ignore.
      else
        raise e
      end
    end
  end
  
  #Parses the arguments given. Proxy-object-arguments will be their natural objects in the subprocess.
  def self.args_parse(args)
    if args.is_a?(Array)
      newargs = []
      args.each do |val|
        if val.is_a?(Knj::Process_meta::Proxy_obj)
          newargs << {"type" => "proxy_obj", "var_name" => val._process_meta_args[:name]}
        else
          newargs << Knj::Process_meta.args_parse(val)
        end
      end
      
      return newargs
    elsif args.is_a?(Hash)
      newargs = {}
      args.each do |key, val|
        if key.is_a?(Knj::Process_meta::Proxy_obj)
          key = {"type" => "proxy_obj", "var_name" => key._process_meta_args[:name]}
        else
          key = Knj::Process_meta.args_parse(key)
        end
        
        if val.is_a?(Knj::Process_meta::Proxy_obj)
          val = {"type" => "proxy_obj", "var_name" => val._process_meta_args[:name]}
        else
          val = Knj::Process_meta.args_parse(val)
        end
        
        newargs[key] = val
      end
      
      return newargs
    else
      return args
    end
  end
  
  #Parses the special hashes to reflect the natural objects instead of proxy-objects.
  def self.args_parse_back(args, objects)
    if args.is_a?(Array)
      newargs = []
      args.each do |val|
        newargs << Knj::Process_meta.args_parse_back(val, objects)
      end
      
      return newargs
    elsif args.is_a?(Hash) and args["type"] == "proxy_obj" and args.key?("var_name")
      raise "No object by that var-name: '#{args["var_name"]}' in '#{objects}'." if !objects.key?(args["var_name"])
      return objects[args["var_name"]]
    elsif args.is_a?(Hash)
      newargs = {}
      args.each do |key, val|
        newargs[Knj::Process_meta.args_parse_back(key, objects)] = Knj::Process_meta.args_parse_back(val, objects)
      end
      
      return newargs
    else
      return args
    end
  end
  
  #Executes a static call in the subprocess but does not capture or return the result. Useful if the static method returns an object that would load a library after being un-marshaled.
  def static_noret(const, method_name, *args, &block)
    res = @process.send(
      "obj" => {
        "type" => "static",
        "const" => const,
        "method_name" => method_name,
        "capture_return" => false,
        "args" => Knj::Process_meta.args_parse(args),
      },
      &block
    )
    
    return res["result"] if res["type"] == "call_const_success"
    raise "Unknown result: '#{res}'."
  end
  
  #Executes a static method on a class in the sub-process.
  def static(const, method_name, *args, &block)
    res = @process.send(
      "obj" => {
        "type" => "static",
        "const" => const,
        "method_name" => method_name,
        "capture_return" => true,
        "args" => Knj::Process_meta.args_parse(args),
      },
      &block
    )
    
    return res["result"] if res["type"] == "call_const_success"
    raise "Unknown result: '#{res}'."
  end
  
  #Spawns a new object in the subprocess by that classname, with those arguments and with that block.
  def new(class_name, *args, &block)
    #We need to check finalizers first, so we wont accidently reuse an ID, which will then be unset in the process.
    self.check_finalizers
    
    #Spawn and return the object.
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
          "args" => Knj::Process_meta.args_parse(args)
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
    return "Unknown result: '#{res}'."
  end
  
  #Calls a method on an object and returns the result.
  def call_object(args, &block)
    self.check_finalizers
    
    if args.key?("capture_return")
      capture_return = args["capture_return"]
    else
      capture_return = true
    end
    
    if args["buffered"]
      type = "call_object_buffered"
    else
      type = "call_object_block"
    end
    
    res = @process.send(
      {
        "buffer_use" => args["buffer_use"],
        "obj" => {
          "type" => type,
          "var_name" => args["var_name"],
          "method_name" => args["method_name"],
          "capture_return" => capture_return,
          "args" => Knj::Process_meta.args_parse(args["args"])
        }
      },
      &block
    )
    
    return res["result"] if res.is_a?(Hash) and res["type"] == "call_object_success"
    raise "Unknown result: '#{res}'."
  end
  
  def proxy_from_eval(eval_str)
    proxy_obj = Knj::Process_meta::Proxy_obj.new(:process_meta => self)
    var_name = proxy_obj.__id__
    proxy_obj._process_meta_args[:name] = var_name
    
    res = @process.send(
      "obj" => {
        "type" => "proxy_from_eval",
        "str" => eval_str,
        "var_name" => var_name
      }
    )
    
    return proxy_obj
  end
  
  def proxy_from_static(class_name, method_name, *args)
    proxy_obj = Knj::Process_meta::Proxy_obj.new(:process_meta => self)
    var_name = proxy_obj.__id__
    proxy_obj._process_meta_args[:name] = var_name
    
    res = @process.send(
      "obj" => {
        "type" => "proxy_from_static",
        "const" => class_name,
        "method_name" => method_name,
        "var_name" => var_name,
        "args" => Knj::Process_meta.args_parse(args)
      }
    )
    
    return proxy_obj
  end
  
  #Returns a proxy-object to a object given from a call.
  def proxy_from_call(proxy_obj_to_call, method_name, *args)
    proxy_obj = Knj::Process_meta::Proxy_obj.new(:process_meta => self)
    var_name = proxy_obj.__id__
    proxy_obj._process_meta_args[:name] = var_name
    
    res = @process.send(
      "obj" => {
        "type" => "proxy_from_call",
        "proxy_obj" => proxy_obj_to_call.__id__,
        "method_name" => method_name,
        "var_name" => var_name,
        "args" => Knj::Process_meta.args_parse(args)
      }
    )
    
    return proxy_obj
  end
  
  #Returns true if the given name exists in the subprocess-objects-hash.
  def proxy_has?(var_name)
    self.check_finalizers
    
    begin
      res = @process.send(
        "obj" => {
          "type" => "call_object_block",
          "var_name" => var_name,
          "method_name" => "__id__",
          "args" => []
        }
      )
    rescue => e
      return false if e.message.to_s.match(/^No object by that name/)
      raise e
    end
    
    return true
  end
  
  #Destroyes the project and unsets all variables on the Process_meta-object.
  def destroy
    @process.send("obj" => {"type" => "exit"})
    @err_thread.kill if @err_thread
    @process.destroy
    
    begin
      Process.kill("TERM", @pid)
    rescue Errno::ESRCH
      #Process is already dead - ignore.
    end
    
    begin
      sleep 0.1
      process_exists = Knj::Unix_proc.list("pids" => [@pid])
      raise "Process exists." if !process_exists.empty?
    rescue => e
      raise e if e.message != "Process exists."
      
      begin
        Process.kill(9, pid) if process_exists
      rescue Errno::ESRCH => e
        raise e if e.message != "No such process"
      end
      
      retry
    end
    
    @process = nil
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
    ObjectSpace.define_finalizer(self, @args[:process_meta].method(:proxy_finalizer))
  end
  
  #This proxies all method-calls through the process-handeler and returns the result as the object was precent inside the current process-memory, even though it is not.
  def method_missing(method_name, *args, &block)
    raise "No arguments on the object?" if !@args
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
  
  def _pm_send_noret(method_name, *args, &block)
    @args[:process_meta].call_object(
      {
        "var_name" => @args[:name],
        "method_name" => method_name,
        "args" => args,
        "buffer_use" => @_process_meta_block_buffer_use,
        "capture_return" => false
      },
      &block
    )
  end
  
  def _pm_buffered_caller(args)
    return Knj::Process_meta::Proxy_obj::Buffered_caller.new({
      :name => @args[:name],
      :process_meta => @args[:process_meta]
    }.merge(args))
  end
end

class Knj::Process_meta::Proxy_obj::Buffered_caller
  def initialize(args)
    @args = args
    @buffer = []
    @mutex = Mutex.new
    @mutex_write = Mutex.new
    @count = 0
    @debug = @args[:debug] if @args[:debug]
    
    if @args[:count_to]
      @count_to = @args[:count_to]
    else
      @count_to = 1000
    end
    
    @buffer_max = @count_to * 2
    @threads = [] if @args[:async]
  end
  
  def method_missing(method_name, *args)
    if method_name.to_s == @args[:method_name].to_s
      self._pm_call(*args)
    else
      raise NoMethodError, "No such method: '#{method_name}'."
    end
  end
  
  def _pm_call(*args)
    raise @raise_error if @raise_error
    
    @mutex.synchronize do
      while @count >= @count_to and @buffer.length >= @buffer_max
        STDOUT.print "Waiting for write to complete...\n" if @debug
        sleep 0.1
      end
      
      STDOUT.print "Adding to buffer #{@buffer.length}...\n" if @debug
      @buffer << args
      @count += 1
    end
    
    self._pm_flush if @count >= @count_to and !@writing
    return nil
  end
  
  def _pm_flush(*args)
    raise @raise_error if @raise_error
    
    buffer = nil
    @mutex.synchronize do
      buffer = @buffer
      @buffer = []
      @count = 0
    end
    
    if @args[:async]
      begin
        @threads << Thread.new do
          self._pm_flush_real(buffer)
        end
      rescue => e
        @raise_error = e
      end
      
      return nil
    else
      return self._pm_flush_real(buffer)
    end
  end
  
  def _pm_flush_real(buffer)
    @mutex_write.synchronize do
      STDOUT.print "Writing...\n" if @debug
      @writing = true
      
      begin
        return @args[:process_meta].call_object(
          "var_name" => @args[:name],
          "method_name" => @args[:method_name],
          "args" => buffer,
          "buffered" => true,
          "capture_return" => false
        )
      ensure
        @writing = false
      end
    end
  end
  
  def _pm_close
    self._pm_flush
    
    if @args[:async]
      @threads.each do |thread|
        thread.join
      end
    end
    
    raise @raise_error if @raise_error
  end
end