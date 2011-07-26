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
		filepath = Knj::Php.realpath(args[:filepath])
		defname = def_name_for_file_path(filepath)
		
		evalcont = "class Knj::Compiler::Container; def self.#{defname};"
		evalcont += File.read(filepath)
		evalcont += ";end;end"
		
		eval(evalcont, nil, args[:fileident])
    @compiled[filepath] = Time.new
	end
	
	#Returns the method name for a filepath.
	def def_name_for_file_path(filepath)
		return filepath.gsub("/", "_").gsub(".", "_")
	end
	
	#Compile and evaluate a file - it will be cached.
	def eval_file(args)
    filepath = Knj::Php.realpath(args[:filepath])
    
		#Compile if it hasnt been compiled yet.
		@mutex.synchronize do
      compile_file(args) if !@compiled.has_key?(filepath)
      
      #Compile if modified time has been changed.
      mtime = File.mtime(filepath)
      compile_file(args) if @compiled[filepath] < mtime
    end
    
		#Call the compiled function.
		defname = def_name_for_file_path(filepath)
		Knj::Compiler::Container.send(defname)
	end
	
	#This class holds the compiled methods.
	class Knj::Compiler::Container; end
end