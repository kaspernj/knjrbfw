class Knj::Gettext_threadded
  attr_reader :langs, :args
  
  def initialize(args = {})
    @args = {
      :encoding => "utf-8"
    }.merge(args)
    @langs = {}
    @dirs = []
    load_dir(@args["dir"]) if @args["dir"]
  end
  
  def load_dir(dir)
    @dirs << dir
    check_folders = ["LC_MESSAGES", "LC_ALL"]
    
    Dir.new(dir).each do |file|
      fn = "#{dir}/#{file}"
      if File.directory?(fn) and file.match(/^[a-z]{2}_[A-Z]{2}$/)
        @langs[file] = {} if !@langs[file]
        
        check_folders.each do |fname|
          fpath = "#{dir}/#{file}/#{fname}"
          
          if File.exists?(fpath) and File.directory?(fpath)
            Dir.new(fpath).each do |pofile|
              if pofile.match(/\.po$/)
                pofn = "#{dir}/#{file}/#{fname}/#{pofile}"
                
                cont = nil
                File.open(pofn, {:encoding => @args[:encoding]}) do |fp|
                  cont = fp.read
                end
                
                cont.scan(/msgid\s+\"(.+)\"\nmsgstr\s+\"(.+)\"\n\n/) do |match|
                  @langs[file][match[0]] = match[1]
                end
              end
            end
          end
        end
      end
    end
  end
  
  def trans(locale, str)
    locale = locale.to_s
    str = str.to_s
    
    if !@langs.key?(locale)
      raise "Locale was not found: '#{locale}' in '#{@langs.keys.join(", ")}'."
    end
    
    return str if !@langs[locale].key?(str)
    return @langs[locale][str]
  end
  
  #This function can be used to make your string be recognized by gettext tools.
  def gettext(str, locale)
    return trans(locale, str)
  end
  
  #Returns a hash with the language ID string as key and the language human-readable-title as value.
  def lang_opts
    langs = {}
    @langs.keys.sort.each do |lang|
      title = nil
      
      @dirs.each do |dir|
        title_file_path = "#{dir}/#{lang}/title.txt"
        if File.exists?(title_file_path)
          title = File.read(title_file_path).to_s.strip
        else
          title = lang.to_s.strip
        end
        
        break if title
      end
      
      langs[lang] = title
    end
    
    return langs
  end
end