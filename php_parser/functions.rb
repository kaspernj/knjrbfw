class Knj::Php_parser
	def func_args(func_name)
		func_arg_count = 0
		args = []
		
		loop do
			if match = self.matchclear(/\A\$#{@regex_varname}\s*(,\s*|)/)
				args << {
					"varname" => match[1],
					"newname" => "phpvar_#{match[1]}"
				}
			elsif match = self.matchclear(/\A\)\s*\{/)
				break
			else
				raise "Could not match function arguments."
			end
		end
		
		@retcont += "#{self.tabs}module Knj::Php_parser::Functions\n"
		@tabs += 1
		@retcont += "#{self.tabs}def self.#{func_name}("
		
		first = true
		args.each do |arg|
			@retcont += ", " if !first
			first = false if first
			@retcont += arg["newname"]
		end
		
		@retcont += ")\n"
		@tabs += 1
		@funcs_started += 1
		
		self.search_newstuff
	end
	
	def func_args_single_given
		arg_found = false
		
		loop do
			if !arg_found and match = self.matchclear(/\A\"/)
				@retcont += "\""
				self.match_semi
				@retcont += ")"
				arg_found = true
			elsif !arg_found and match = self.matchclear(/\A\$(#{@regex_varname})/)
				@retcont += "phpvar_#{match[1]}"
				arg_found = true
			elsif arg_found and match = self.matchclear(/\A\.\s*/)
				@retcont += " + "
				arg_found = false
			elsif arg_found and match = self.matchclear(/\A;/)
				@retcont += "\n"
				break
			else
				raise "Could not figure out what to do."
			end
		end
	end
	
	def func_args_given
		arg_found = false
		
		loop do
			if !arg_found and match = self.matchclear(/\A\"/)
				@retcont += "\""
				self.match_semi
				@retcont += ")"
				arg_found = true
			elsif !arg_found and match = self.matchclear(/\A\$(#{@regex_varname})/)
				@retcont += "phpvar_#{match[1]}"
				arg_found = true
			elsif arg_found and match = self.matchclear(/\A\.\s*/)
				@retcont += " + "
				arg_found = false
			elsif arg_found and match = self.matchclear(/\A\)\s*;/)
				@retcont += "\n"
				break
			else
				raise "Could not figure out what to do."
			end
		end
	end
	
	def match_semi
		loop do
			if match = self.matchclear(/\A[A-z\d_\.]+/)
				@retcont += match[0]
			elsif match = self.matchclear(/\A\"/)
				@retcont += "\""
				break
			else
				raise "Could not figure out what to do."
			end
		end
	end
end