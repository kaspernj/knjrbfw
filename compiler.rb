class Knj::Compiler
	def initialize(args = {})
		@args = args
		@compiled = {}
	end
	
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
	
	def def_name_for_file_path(filepath)
		return filepath.gsub("/", "_").gsub(".", "_")
	end
	
	def eval_file(filepath)
		load filepath
		return nil
		
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
	
	class Knj::Compiler::Container
		
	end
end