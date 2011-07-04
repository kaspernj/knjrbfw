#This class can compile Ruby-files into Ruby-methods on a special class and then call these methods to run the code from the file. The theory is that this can be faster...
class Knj::Compiler
	def initialize(args = {})
		@args = args
		@compiled = {}
	end
	
	#Compiles file into cache as a method.
	def compile_file(filepath)
		raise "File does not exist." if !File.exist?(filepath)
		filepath = Knj::Php.realpath(filepath)
		defname = def_name_for_file_path(filepath)
		
		evalcont = "class Knj::Compiler::Container; def self.#{defname};"
		evalcont += File.read(filepath)
		evalcont += ";end;end"
		
		eval(evalcont)
		@compiled[filepath] = Time.new
	end
	
	#Returns the method name for a filepath.
	def def_name_for_file_path(filepath)
		return filepath.gsub("/", "_").gsub(".", "_")
	end
	
	#Compile and evaluate a file - it will be cached.
	def eval_file(filepath)
		#Compile if it hasnt been compiled yet.
		compile_file(filepath) if !@compiled.has_key?(filepath)
		filepath = Knj::Php.realpath(filepath)
		
		#Compile if modified time has been changed.
		mtime = File.new(filepath).mtime
		oldmtime = @compiled[filepath]
		@compiled.has_key?(filepath) if oldmtime < mtime
			
		#Call the compiled function.
		defname = def_name_for_file_path(filepath)
		Knj::Compiler::Container.send(defname)
	end
	
	#This class holds the compiled methods.
	class Knj::Compiler::Container
		
	end
end