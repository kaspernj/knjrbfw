class Knj::Objects
  attr_reader :args, :events, :data
  
  def initialize(args)
    require "#{$knjpath}arrayext"
    require "#{$knjpath}event_handler"
    require "#{$knjpath}hash_methods"
    
    @callbacks = {}
    @args = Knj::ArrayExt.hash_sym(args)
    @args[:col_id] = :id if !@args[:col_id]
    @args[:class_pre] = "class_" if !@args[:class_pre]
    @args[:module] = Kernel if !@args[:module]
    @args[:cache] = :weak if !@args.key?(:cache)
    @objects = {}
    @locks = {}
    @data = {}
    @mutex_require = Mutex.new
    
    require "weakref" if @args[:cache] == :weak and !Kernel.const_defined?(:WeakRef)
    
    @events = Knj::Event_handler.new
    @events.add_event(
      :name => :no_html,
      :connections_max => 1
    )
    @events.add_event(
      :name => :no_date,
      :connections_max => 1
    )
    @events.add_event(
      :name => :missing_class,
      :connections_max => 1
    )
    
    raise "No DB given." if !@args[:db] and !@args[:custom]
    raise "No class path given." if !@args[:class_path] and (@args[:require] or !@args.key?(:require))
    
    if args[:require_all]
      require "#{$knjpath}php"
      loads = []
      
      Dir.foreach(@args[:class_path]) do |file|
        next if file == "." or file == ".." or !file.match(/\.rb$/)
        file_parsed = file
        file_parsed.gsub!(@args[:class_pre], "") if @args.key?(:class_pre)
        file_parsed.gsub!(/\.rb$/, "")
        file_parsed = Knj::Php.ucwords(file_parsed)
        
        loads << file_parsed
        self.requireclass(file_parsed, {:load => false})
      end
      
      loads.each do |load_class|
        self.load_class(load_class)
      end
    end
  end
  
  def init_class(classname)
    return false if @objects.key?(classname)
    @objects[classname] = {}
    @locks[classname] = Mutex.new
  end
  
  #Returns a cloned version of the @objects variable. Cloned because iteration on it may crash some of the other methods in Ruby 1.9+
  def objects
    objs_cloned = {}
    
    @objects.keys.each do |key|
      objs_cloned[key] = @objects[key].clone
    end
    
    return objs_cloned
  end
  
  def db
    return @args[:db]
  end
  
  #Returns the total count of objects currently held by this instance.
  def count_objects
    count = 0
    @objects.keys.each do |key|
      count += @objects[key].length
    end
    
    return count
  end
  
  def connect(args, &block)
    raise "No object given." if !args["object"]
    raise "No signals given." if !args.key?("signal") and !args.key?("signals")
    args["block"] = block if block_given?
    @callbacks[args["object"]] = {} if !@callbacks[args["object"]]
    conn_id = @callbacks[args["object"]].length.to_s
    @callbacks[args["object"]][conn_id] = args
  end
  
  def call(args, &block)
    classstr = args["object"].class.to_s
    
    if @callbacks.key?(classstr)
      @callbacks[classstr].clone.each do |callback_key, callback|
        docall = false
        
        if callback.key?("signal") and args.key?("signal") and callback["signal"] == args["signal"]
          docall = true
        elsif callback["signals"] and args["signal"] and callback["signals"].index(args["signal"]) != nil
          docall = true
        end
        
        next if !docall
        
        if callback["block"]
          callargs = []
          arity = callback["block"].arity
          if arity <= 0
            #do nothing
          elsif arity == 1
            callargs << args["object"]
          else
            raise "Unknown number of arguments: #{arity}"
          end
          
          callback["block"].call(*callargs)
        elsif callback["callback"]
          Knj::Php.call_user_func(callback["callback"], args)
        else
          raise "No valid callback given."
        end
      end
    end
  end
  
  def requireclass(classname, args = {})
    classname = classname.to_sym
    return false if @objects.key?(classname)
    
    @mutex_require.synchronize do
      #Maybe the classname got required meanwhile the synchronized wait - check again.
      return false if @objects.key?(classname)
      
      if (@args[:require] or !@args.key?(:require)) and (!args.key?(:require) or args[:require])
        filename = "#{@args[:class_path]}/#{@args[:class_pre]}#{classname.to_s.downcase}.rb"
        filename_req = "#{@args[:class_path]}/#{@args[:class_pre]}#{classname.to_s.downcase}"
        raise "Class file could not be found: #{filename}." if !File.exists?(filename)
        require filename_req
      end
      
      if args[:class]
        classob = args[:class]
      else
        begin
          classob = @args[:module].const_get(classname)
        rescue NameError => e
          if @events.connected?(:missing_class)
            @events.call(:missing_class, {
              :class => classname
            })
            classob = @args[:module].const_get(classname)
          else
            raise e
          end
        end
      end
      
      if (classob.respond_to?(:load_columns) or classob.respond_to?(:datarow_init)) and (!args.key?(:load) or args[:load])
        self.load_class(classname, args)
      end
      
      self.init_class(classname)
    end
  end
  
  #Loads a Datarow-class by calling various static methods.
  def load_class(classname, args = {})
    if args[:class]
      classob = args[:class]
    else
      classob = @args[:module].const_get(classname)
    end
    
    pass_arg = Knj::Hash_methods.new(:ob => self, :db => @args[:db])
    classob.load_columns(pass_arg) if classob.respond_to?(:load_columns)
    classob.datarow_init(pass_arg) if classob.respond_to?(:datarow_init)
  end
  
  #Gets an object from the ID or the full data-hash in the database.
  def get(classname, data)
    classname = classname.to_sym
    
    if data.is_a?(Integer) or data.is_a?(String) or data.is_a?(Fixnum)
      id = data.to_i
    elsif data.is_a?(Hash) and data.key?(@args[:col_id].to_sym)
      id = data[@args[:col_id].to_sym].to_i
    elsif data.is_a?(Hash) and data.key?(@args[:col_id].to_s)
      id = data[@args[:col_id].to_s].to_i
    elsif
      raise Knj::Errors::InvalidData, "Unknown data: '#{data.class.to_s}'."
    end
    
    if @objects.key?(classname) and @objects[classname].key?(id)
      case @args[:cache]
        when :weak
          begin
            obj = @objects[classname][id].__getobj__
            
            if obj.is_a?(Knj::Datarow) and obj.respond_to?(:table) and obj.respond_to?(:id) and obj.table.to_sym == classname and obj.id.to_i == id
              return obj
            else
              #This actually happens sometimes... WTF!? - knj
              raise WeakRef::RefError
            end
          rescue WeakRef::RefError
            @objects[classname].delete(id)
          rescue NoMethodError => e
            #NoMethodError because the object might have been deleted from the cache, and __getobj__ then throws it.
            raise e if e.message != "undefined method `__getobj__' for nil:NilClass"
          end
        else
          return @objects[classname][id]
      end
    end
    
    self.requireclass(classname) if !@objects.key?(classname)
    
    @locks[classname].synchronize do
      #Maybe the object got spawned while we waited for the lock? If so we shouldnt spawn another instance.
      if @objects[classname].key?(id)
        return self.get(classname, data)
      end
      
      #Spawn object.
      if @args[:datarow] or @args[:custom]
        obj = @args[:module].const_get(classname).new(Knj::Hash_methods.new(:ob => self, :data => data))
      else
        args = [data]
        args = args | @args[:extra_args] if @args[:extra_args]
        obj = @args[:module].const_get(classname).new(*args)
      end
      
      #Save object in cache.
      case @args[:cache]
        when :weak
          @objects[classname][id] = WeakRef.new(obj)
        when :none
          return obj
        else
          @objects[classname][id] = obj
      end
    end
    
    #Return spawned object.
    return obj
  end
  
  def object_finalizer(id)
    classname = @objects_idclass[id]
    if classname
      @objects[classname].delete(id)
      @objects_idclass.delete(id)
    end
  end
  
  def get_by(classname, args = {})
    classname = classname.to_sym
    self.requireclass(classname)
    classob = @args[:module].const_get(classname)
    
    raise "list-function has not been implemented for #{classname}" if !classob.respond_to?("list")
    
    args["limit"] = 1
    self.list(classname, args) do |obj|
      return obj
    end
    
    return false
  end
  
  def get_try(obj, col_name, obj_name = nil)
    if !obj_name
      if match = col_name.to_s.match(/^(.+)_id$/)
        obj_name = Knj::Php.ucwords(match[1]).to_sym
      else
        raise "Could not figure out objectname for: #{col_name}."
      end
    end
    
    id_data = obj[col_name].to_i
    return false if id_data.to_i <= 0
    
    begin
      return self.get(obj_name, id_data)
    rescue Knj::Errors::NotFound
      return false
    end
  end
  
  #Returns an array-list of objects. If given a block the block will be called for each element and memory will be spared if running weak-link-mode.
  def list(classname, args = {}, &block)
    args = {} if args == nil
    classname = classname.to_sym
    self.requireclass(classname)
    classob = @args[:module].const_get(classname)
    
    raise "list-function has not been implemented for '#{classname}'." if !classob.respond_to?("list")
    
    if @args[:datarow] or @args[:custom]
      ret = classob.list(Knj::Hash_methods.new(:args => args, :ob => self, :db => @args[:db]), &block)
    else
      realargs = [args]
      realargs = realargs | @args[:extra_args] if @args[:extra_args]
      ret = classob.list(*realargs, &block)
    end
    
    #If 'ret' is an array and a block is given then the list-method didnt return blocks. We emulate it instead with the following code.
    if block and ret.is_a?(Array)
      ret.each do |obj|
        block.call(obj)
      end
      return nil
    elsif block and ret != nil
      raise "Return should return nil because of block but didnt. It wasnt an array either..."
    elsif block
      return nil
    else
      return ret
    end
  end
  
  #Returns select-options-HTML for inserting into a HTML-select-element.
  def list_opts(classname, args = {})
    Knj::ArrayExt.hash_sym(args)
    classname = classname.to_sym
    
    if args[:list_args].is_a?(Hash)
      list_args = args[:list_args]
    else
      list_args = {}
    end
    
    html = ""
    
    if args[:addnew] or args[:add]
      html << "<option"
      html << " selected=\"selected\"" if !args[:selected]
      html << " value=\"\">#{_("Add new")}</option>"
    end
    
    self.list(classname, args[:list_args]) do |object|
      html << "<option value=\"#{object.id.html}\""
      
      selected = false
      if args[:selected].is_a?(Array) and args[:selected].index(object) != nil
        selected = true
      elsif args[:selected] and args[:selected].respond_to?("is_knj?") and args[:selected].id.to_s == object.id.to_s
        selected = true
      end
      
      html << " selected=\"selected\"" if selected
      
      obj_methods = object.class.instance_methods(false)
      
      begin
        if obj_methods.index("name") != nil or obj_methods.index(:name) != nil
          objhtml = object.name.html
        elsif obj_methods.index("title") != nil or obj_methods.index(:title) != nil
          objhtml = object.title.html
        elsif object.respond_to?(:data)
          obj_data = object.data
          
          if obj_data.key?(:name)
            objhtml = obj_data[:name]
          elsif obj_data.key?(:title)
            objhtml = obj_data[:title]
          end
        else
          objhtml = ""
        end
        
        raise "Could not figure out which name-method to call?" if !objhtml
        html << ">#{objhtml}</option>"
      rescue Exception => e
        html << ">[#{object.class.name}: #{e.message}]</option>"
      end
    end
    
    return html
  end
  
  #Returns a hash which can be used to generate HTML-select-elements.
  def list_optshash(classname, args = {})
    Knj::ArrayExt.hash_sym(args)
    classname = classname.to_sym
    
    if args[:list_args].is_a?(Hash)
      list_args = args[:list_args]
    else
      list_args = {}
    end
    
    if RUBY_VERSION[0..2] == 1.8 and Knj::Php.class_exists("Dictionary")
      print "Spawning dictionary.\n" if args[:debug]
      list = Dictionary.new
    else
      print "Spawning normal hash.\n" if args[:debug]
      list = {}
    end
    
    if args[:addnew] or args[:add]
      list["0"] = _("Add new")
    elsif args[:choose]
      list["0"] = _("Choose") + ":"
    elsif args[:all]
      list["0"] = _("All")
    elsif args[:none]
      list["0"] = _("None")
    end
    
    print "Doing loop\n" if args[:debug]
    self.list(classname, args[:list_args]) do |object|
      print "Object: #{object.id}\n" if args[:debug]
      
      if object.respond_to?(:name)
        list[object.id] = object.name
      elsif object.respond_to?(:title)
        list[object.id] = object.title
      else
        raise "Object of class '#{object.class.name}' doesnt support 'name' or 'title."
      end
    end
    
    print "Returning...\n" if args[:debug]
    return list
  end
  
  #Returns a list of a specific object by running specific SQL against the database.
  def list_bysql(classname, sql, args = nil, &block)
    classname = classname.to_sym
    ret = [] if !block
    qargs = nil
    
    if args
      args.each do |key, val|
        case key
          when :cloned_ubuf
            qargs = {:cloned_ubuf => true}
          else
            raise "Invalid key: '#{key}'."
        end
      end
    end
    
    @args[:db].q(sql, qargs) do |d_obs|
      if block
        block.call(self.get(classname, d_obs))
      else
        ret << self.get(classname, d_obs)
      end
    end
    
    return ret if !block
  end
  
  # Add a new object to the database and to the cache.
  def add(classname, data = {})
    classname = classname.to_sym
    self.requireclass(classname)
    
    if @args[:datarow]
      classobj = @args[:module].const_get(classname)
      if classobj.respond_to?(:add)
        classobj.add(Knj::Hash_methods.new(
          :ob => self,
          :db => self.db,
          :data => data
        ))
      end
      
      required_data = classobj.required_data
      required_data.each do |req_data|
        if !data.key?(req_data[:col])
          raise "No '#{req_data[:class]}' given by the data '#{req_data[:col]}'."
        end
        
        begin
          obj = self.get(req_data[:class], data[req_data[:col]])
        rescue Knj::Errors::NotFound
          raise "The '#{req_data[:class]}' by ID '#{data[req_data[:col]]}' could not be found with the data '#{req_data[:col]}'."
        end
      end
      
      ins_id = @args[:db].insert(classobj.table, data, {:return_id => true})
      retob = self.get(classname, ins_id)
    elsif @args[:custom]
      classobj = @args[:module].const_get(classname)
      retob = classobj.add(Knj::Hash_methods.new(
        :ob => self,
        :data => data
      ))
    else
      args = [data]
      args = args | @args[:extra_args] if @args[:extra_args]
      retob = @args[:module].const_get(classname).add(*args)
    end
    
    self.call("object" => retob, "signal" => "add")
    if retob.respond_to?(:add_after)
      retob.send(:add_after, {})
    end
    
    return retob
  end
  
  #Adds several objects to the database at once. This is faster than adding every single object by itself, since this will do multi-inserts if supported by the database.
  def adds(classname, datas)
    if !@args[:datarow]
      datas.each do |data|
        @args[:module].const_get(classname).add(*args)
        self.call("object" => retob, "signal" => "add")
      end
    else
      if @args[:module].const_get(classname).respond_to?(:add)
        datas.each do |data|
          @args[:module].const_get(classname).add(Knj::Hash_methods.new(
            :ob => self,
            :db => self.db,
            :data => data
          ))
        end
      end
      
      db.insert_multi(classname, datas)
    end
  end
  
  #Calls a static method on a class. Passes the d-variable which contains the Objects-object, database-reference and more...
  def static(class_name, method_name, *args, &block)
    raise "Only available with datarow enabled." if !@args[:datarow] and !@args[:custom]
    class_name = class_name
    method_name = method_name
    
    self.requireclass(class_name)
    class_obj = @args[:module].const_get(class_name)
    
    #Sometimes this raises the exception but actually responds to the class? Therefore commented out. - knj
    #raise "The class '#{class_obj.name}' has no such method: '#{method_name}' (#{class_obj.methods.sort.join(", ")})." if !class_obj.respond_to?(method_name)
    
    pass_args = []
    
    if @args[:datarow]
      pass_args << Knj::Hash_methods.new(:ob => self, :db => self.db)
    else
      pass_args << Knj::Hash_methods.new(:ob => self)
    end
    
    args.each do |arg|
      pass_args << arg
    end
    
    class_obj.send(method_name, *pass_args, &block)
  end
  
  #Unset object. Do this if you are sure, that there are no more references left. This will be done automatically when deleting it.
  def unset(object)
    if object.is_a?(Array)
      object.each do |obj|
        unset(obj)
      end
      return nil
    end
    
    classname = object.class.name
    
    if @args[:module]
      classname = classname.gsub(@args[:module].name + "::", "")
    end
    
    classname = classname.to_sym
    
    #if !@objects.key?(classname)
      #raise "Could not find object class in cache: #{classname}."
    #elsif !@objects[classname].key?(object.id.to_i)
      #errstr = ""
      #errstr << "Could not unset object from cache.\n"
      #errstr << "Class: #{object.class.name}.\n"
      #errstr << "ID: #{object.id}.\n"
      #errstr << "Could not find object ID in cache."
      #raise errstr
    #else
      @objects[classname].delete(object.id.to_i)
    #end
  end
  
  def unset_class(classname)
    if classname.is_a?(Array)
      classname.each do |classn|
        self.unset_class(classn)
      end
      
      return false
    end
    
    classname = classname.to_sym
    
    return false if !@objects.key?(classname)
    @objects.delete(classname)
  end
  
  #Delete an object. Both from the database and from the cache.
  def delete(object)
    self.call("object" => object, "signal" => "delete_before")
    self.unset(object)
    obj_id = object.id
    object.delete if object.respond_to?(:delete)
    
    if @args[:datarow]
      #If autodelete is set by 'has_many'-method, go through it and delete the various objects first.
      object.class.autodelete_data.each do |adel_data|
        self.list(adel_data[:classname], {adel_data[:colname].to_s => object.id}) do |obj_del|
          self.delete(obj_del)
        end
      end
      
      #If depend is set by 'has_many'-method, check if any objects exists and raise error if so.
      object.class.depending_data.each do |dep_data|
        obj = self.get_by(dep_data[:classname], {dep_data[:colname].to_s => object.id})
        if obj
          raise "Cannot delete <#{object.class.name}:#{object.id}> because <#{obj.class.name}:#{obj.id}> depends on it."
        end
      end
      
      #Delete any translations that has been set on the object by 'has_translation'-method.
      if object.class.translations
        _kas.trans_del(object)
      end
      
      @args[:db].delete(object.table, {:id => obj_id})
    end
    
    self.call("object" => object, "signal" => "delete")
    object.destroy
  end
  
  #Deletes several objects as one. If running datarow-mode it checks all objects before it starts to actually delete them. Its faster than deleting every single object by itself...
  def deletes(objs)
    if !@args[:datarow]
      objs.each do |obj|
        self.delete(obj)
      end
    else
      arr_ids = []
      ids = []
      objs.each do |obj|
        ids << obj.id
        if ids.length >= 1000
          arr_ids << ids
          ids = []
        end
        
        obj.delete if obj.respond_to?(:delete)
      end
      
      arr_ids << ids if ids.length > 0
      arr_ids.each do |ids|
        @args[:db].delete(objs[0].table, {:id => ids})
      end
    end
  end
  
  # Try to clean up objects by unsetting everything, start the garbagecollector, get all the remaining objects via ObjectSpace and set them again. Some (if not all) should be cleaned up and our cache should still be safe... dirty but works.
  def clean(classn)
    return false if @args[:cache] == :weak or @args[:cache] == :none
    
    if classn.is_a?(Array)
      classn.each do |realclassn|
        self.clean(realclassn)
      end
    else
      return false if !@objects.key?(classn)
      @objects[classn] = {}
      GC.start
    end
  end
  
  #Erases the whole cache and regenerates is from ObjectSpace if not running weak-link-caching. If running weaklink-caching then only removes the dead links.
  def clean_all
    return self.clean_all_weak if @args[:cache] == :weak
    return false if @args[:cache] == :none
    
    classnames = []
    @objects.keys.each do |classn|
      classnames << classn
    end
    
    classnames.each do |classn|
      @objects[classn] = {}
    end
    
    GC.start
    self.clean_recover
  end
  
  #Runs through all objects-weaklink-references and removes the weaklinks if the object has been recycled.
  def clean_all_weak
    @objects.keys.each do |classn|
      @objects[classn].keys.each do |object_id|
        object = @objects[classn][object_id]
        
        begin
          if !object or !object.weakref_alive?
            @objects[classn].delete(object_id)
          end
        rescue WeakRef::RefError
          #This happens if the object has been collected.
          @objects[classn].delete(object_id)
        end
      end
    end
  end
  
  #Regenerates cache from ObjectSpace. Its pretty dangerous but can be used in envs where WeakRef is not supported (did someone say Rhodes?).
  def clean_recover
    return false if @args[:cache] == :weak or @args[:cache] == :none
    return false if RUBY_ENGINE == "jruby" and !JRuby.objectspace
    
    @objects.keys.each do |classn|
      data = @objects[classn]
      classobj = @args[:module].const_get(classn)
      ObjectSpace.each_object(classobj) do |obj|
        begin
          data[obj.id.to_i] = obj
        rescue => e
          if e.message == "No data on object."
            #Object has been unset - skip it.
            next
          end
          
          raise e
        end
      end
    end
  end
end

require "#{$knjpath}objects/objects_sqlhelper"
