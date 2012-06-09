#Uses Rubinius, Knj::Compiler, RubyVM::InstructionSequence and eval to convert and execute .rhtml-files.
class Knj::Eruby
  attr_reader :connects, :error, :headers, :cookies, :fcgi
  
  #Sets various arguments and prepares for parsing.
  def initialize(args = {})
    @args = args
    
    @tmpdir = "#{Knj::Os.tmpdir}/knj_erb"
    Dir.mkdir(@tmpdir, 0777) if !File.exists?(@tmpdir)
    
    
    #This argument can be used if a shared cache should be used to speed up performance.
    if @args[:cache_hash]
      @cache = @args[:cache_hash]
    else
      @cache = {}
    end
    
    if RUBY_PLATFORM == "java" or RUBY_ENGINE == "rbx"
      @cache_mode = :code_eval
      #@cache_mode = :compile_knj
    elsif RUBY_VERSION.slice(0..2) == "1.9" #and RubyVM::InstructionSequence.respond_to?(:compile_file)
      @cache_mode = :code_eval
      #@cache_mode = :inseq
      #@cache_mode = :compile_knj
    end
    
    if @cache_mode == :compile_knj
      require "#{$knjpath}compiler"
      @compiler = Knj::Compiler.new(:cache_hash => @cache)
    end
    
    self.reset_headers
    self.reset_connects
  end
  
  #Imports and evaluates a new .rhtml-file.
  #===Examples
  # erb.import("/path/to/some_file.rhtml")
  def import(filename)
    @error = false
    Dir.mkdir(@tmpdir) if !File.exists?(@tmpdir)
    filename = File.expand_path(filename)
    raise "File does not exist: #{filename}" unless File.exists?(filename)
    cachename = "#{@tmpdir}/#{filename.gsub("/", "_").gsub(".", "_")}.cache"
    filetime = File.mtime(filename)
    cachetime = File.mtime(cachename) if File.exists?(cachename)
    
    if !File.exists?(cachename) or filetime > cachetime
      Knj::Eruby::Handler.load_file(filename, {:cachename => cachename})
      File.chmod(0777, cachename)
      cachetime = File.mtime(cachename)
      reload_cache = true
    end
    
    begin
      case @cache_mode
        when :compile_knj
          @compiler.eval_file(:filepath => cachename, :fileident => filename)
        when :code_eval
          if @args[:binding_callback]
            binding_use = @args[:binding_callback].call
          else
            eruby_binding = Knj::Eruby::Binding.new
            binding_use = eruby_binding.get_binding
          end
          
          #No reason to cache contents of files - benchmarking showed little to no differene performance-wise, but caching took up a lot of memory, when a lot of files were cached - knj.
          eval(File.read(cachename), binding_use, filename)
        when :inseq
          reload_cache = true if !@cache.key?(cachename)
          
          if reload_cache or @cache[cachename][:time] < cachetime
            @cache[cachename] = {
              :inseq => RubyVM::InstructionSequence.compile(File.read(cachename), filename, nil, 1),
              :time => Time.now
            }
          end
          
          @cache[cachename][:inseq].eval
        else
          loaded_content = Knj::Eruby::Handler.load_file(filename, {:cachename => cachename})
          print loaded_content.evaluate
      end
    rescue SystemExit
      #do nothing.
    rescue => e
      @error = true
      self.handle_error(e)
    end
  end
  
  #Destroyes this object unsetting all variables and clearing all cache.
  def destroy
    @connects.clear if @connects.is_a?(Hash)
    @headers.clear if @headers.is_a?(Array)
    @cookies.clear if @cookies.is_a?(Array)
    
    @cache.clear if @cache.is_a?(Hash) and @args and !@args.key?(:cache_hash)
    @args.clear if @args.is_a?(Hash)
    @args = nil
    @cache = nil
    @connects = nil
    @headers = nil
    @cookies = nil
  end
  
  #Returns various headers as one complete string ready to be used in a HTTP-request.
  def print_headers(args = {})
    header_str = ""
    
    @headers.each do |header|
      header_str << "#{header[0]}: #{header[1]}\n"
    end
    
    @cookies.each do |cookie|
      header_str << "Set-Cookie: #{Knj::Web.cookie_str(cookie)}\n"
    end
    
    header_str << "\n"
    self.reset_headers if @fcgi
    return header_str
  end
  
  #Returns true if containing a status-header.
  def has_status_header?
    @headers.each do |header|
      return true if header[0] == "Status"
    end
    
    return false
  end
  
  #Resets all connections.
  def reset_connects
    @connects = {}
  end
  
  #Resets all headers.
  def reset_headers
    @headers = []
    @cookies = []
  end
  
  #Adds a new header to the list.
  def header(key, value)
    @headers << [key, value]
  end
  
  #Adds a new cookie to the list.
  def cookie(cookie_data)
    @cookies << cookie_data
  end
  
  #Connects a block to a certain event.
  def connect(signal, &block)
    @connects[signal] = [] if !@connects.key?(signal)
    @connects[signal] << block
  end
  
  def printcont(tmp_out, args = {})
    if @fcgi
      @fcgi.print self.print_headers
      tmp_out.rewind
      @fcgi.print tmp_out.read.to_s
    else
      if args[:io] and !args[:custom_io]
        old_out = $stdout
        $stdout = args[:io]
      elsif !args[:custom_io]
        $stdout = STDOUT
      end
      
      if !args[:custom_io]
        print self.print_headers if !args.key?(:with_headers) or args[:with_headers]
        tmp_out.rewind
        print tmp_out.read
      end
    end
  end
  
  def load_return(filename, args = {})
    if !args[:io]
      retio = StringIO.new
      args[:io] = retio
    end
    
    self.load_filename(filename, args)
    
    if !args[:custom_io]
      retio.rewind
      return retio.read
    end
  end
  
  def load_filename(filename, args = {})
    begin
      if !args[:custom_io]
        tmp_out = StringIO.new
        $stdout = tmp_out
      end
      
      self.import(filename)
      
      if @connects["exit"]
        @connects["exit"].each do |block|
          block.call
        end
      end
      
      self.printcont(tmp_out, args)
    rescue SystemExit => e
      self.printcont(tmp_out, args)
    rescue => e
      self.handle_error(e)
      self.printcont(tmp_out, args)
    end
  end
  
  #This method will handle an error without crashing simply adding the error to the print-queue.
  def handle_error(e)
    begin
      if @connects and @connects.key?("error")
        @connects["error"].each do |block|
          block.call(e)
        end
      end
    rescue SystemExit => e
      raise e
    rescue => e
      #An error occurred while trying to run the on-error-block - show this as an normal error.
      print "\n\n<pre>\n\n"
      print "<b>#{Knj::Web.html(e.class.name)}: #{Knj::Web.html(e.message)}</b>\n\n"
      
      e.backtrace.each do |line|
        print "#{Knj::Web.html(line)}\n"
      end
      
      print "</pre>"
    end
    
    print "\n\n<pre>\n\n"
    print "<b>#{Knj::Web.html(e.class.name)}: #{Knj::Web.html(e.message)}</b>\n\n"
    
    e.backtrace.each do |line|
      print "#{Knj::Web.html(line)}\n"
    end
    
    print "</pre>"
  end
end

#Erubis-handler used to print to $stdout.
class Knj::Eruby::Handler < Erubis::Eruby
  include Erubis::StdoutEnhancer
end

#Default binding-object which makes sure the .rhtml-file is running on an empty object.
class Knj::Eruby::Binding
  #Returns the binding to the empty object.
  def get_binding
    return binding
  end
end