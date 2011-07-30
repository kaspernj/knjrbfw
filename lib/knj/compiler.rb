#This class can compile Ruby-files into Ruby-methods on a special class and then call these methods to run the code from the file. The theory is that this can be faster...
class Knj::Compiler
	def initialize(args = {})
		@args = args
		@mutex = Mutex.new
		
		if @args[:cache_hash]
      @compiled = @args[:cache_hash]
    else
      @compiled = {}
    end
	end
	
	#Compiles file into cache as a method.
	def compile_file(args)
		raise "File does not exist." if !File.exist?(args[:filepath])
		defname = def_name_for_file_path(args[:filepath])
		
		evalcont = "class Knj::Compiler::Container; def self.#{defname};"
		evalcont += File.read(args[:filepath])
		evalcont += ";end;end"
		
		eval(evalcont, nil, args[:fileident])
    @compiled[args[:filepath]] = Time.new
	end
	
	#Returns the method name for a filepath.
	def def_name_for_file_path(filepath)
		return filepath.gsub("/", "_").gsub(".", "_")
	end
	
	#Compile and evaluate a file - it will be cached.
	def eval_file(args)
		#Compile if it hasnt been compiled yet.
    if !@compiled.has_key?(args[:filepath])
      @mutex.synchronize do
        compile_file(args) if !@compiled.has_key?(args[:filepath])
      end
    end
    
    #Compile if modified time has been changed.
    mtime = File.mtime(args[:filepath])
    if @compiled[args[:filepath]] < mtime
      @mutex.synchronize do
        compile_file(args)
      end
    end
    
		#Call the compiled function.
		defname = def_name_for_file_path(args[:filepath])
		Knj::Compiler::Container.send(defname)
	end
	
	#This class holds the compiled methods.
	class Knj::Compiler::Container; end
end