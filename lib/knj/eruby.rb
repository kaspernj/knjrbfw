class Knj::Eruby
  attr_reader :fcgi
  attr_reader :connects, :headers, :cookies
  
  def initialize(args = {})
    @args = args
    
    require "tmpdir"
    @tmpdir = "#{Dir.tmpdir}/knj_erb"
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
    elsif RUBY_VERSION.slice(0..2) == "1.9" and RubyVM::InstructionSequence.respond_to?(:compile_file)
      @cache_mode = :inseq
      #@cache_mode = :compile_knj
    end
    
    if @cache_mode == :compile_knj
      require "#{$knjpath}compiler"
      @compiler = Knj::Compiler.new(:cache_hash => @cache)
    end
    
    self.reset_headers
    self.reset_connects
  end
  
  def import(filename)
    Dir.mkdir(@tmpdir) if !File.exists?(@tmpdir)
    filename = File.expand_path(filename)
    raise "File does not exist: #{filename}" if !File.exists?(filename)
    filetime = File.mtime(filename)
    cachename = "#{@tmpdir}/#{filename.gsub("/", "_").gsub(".", "_")}.cache"
    cachetime = File.mtime(cachename) if File.exists?(cachename)
    
    begin
      if !File.exists?(cachename) or filetime > cachetime
        Knj::Eruby::Handler.load_file(filename, {:cachename => cachename})
        cachetime = File.mtime(cachename)
        reload_cache = true
      elsif !@cache.key?(cachename)
        reload_cache = true
      end
      
      case @cache_mode
        when :compile_knj
          @compiler.eval_file(:filepath => cachename, :fileident => filename)
        when :code_eval
          @cache[cachename] = File.read(cachename) if reload_cache
          eval(@cache[cachename], nil, filename)
        when :inseq
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
    rescue Exception => e
      self.handle_error(e)
    end
  end
  
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
  
  def has_status_header?
    @headers.each do |header|
      return true if header[0] == "Status"
    end
    
    return false
  end
  
  def reset_connects
    @connects = {}
  end
  
  def reset_headers
    @headers = []
    @cookies = []
  end
  
  def header(key, value)
    @headers << [key, value]
  end
  
  def cookie(cookie_data)
    @cookies << cookie_data
  end
  
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
    rescue Exception => e
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
      exit
    rescue Exception => e
      #An error occurred while trying to run the on-error-block - show this as an normal error.
      print "\n\n<pre>\n\n"
      print "<b>#{Knj::Web.html(e.class.name)}: #{Knj::Web.html(e.message)}</b>\n\n"
      
      #Lets hide all the stuff in what is not the users files to make it easier to debug.
      bt = e.backtrace
      #to = bt.length - 9
      #bt = bt[0..to]
      
      bt.each do |line|
        print Knj::Web.html(line) + "\n"
      end
      
      print "</pre>"
    end
    
    print "\n\n<pre>\n\n"
    print "<b>#{Knj::Web.html(e.class.name)}: #{Knj::Web.html(e.message)}</b>\n\n"
    
    e.backtrace.each do |line|
      print Knj::Web.html(line) + "\n"
    end
    
    print "</pre>"
  end
end

class Knj::Eruby::Handler < Erubis::Eruby
  include Erubis::StdoutEnhancer
end