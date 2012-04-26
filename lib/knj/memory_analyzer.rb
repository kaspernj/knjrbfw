class Knj::Memory_analyzer
  def initialize
    @printed = {}
  end
  
  def write(to = $stdout)
    to.print "<div style=\"width: 600px;\">\n"
    
    self.garbage_collector(to)
    GC.start
    
    self.arrays(to)
    GC.start
    
    self.hashes(to)
    GC.start
    
    self.constants(to)
    GC.start
    
    self.global_vars(to)
    GC.start
    
    to.print "</div>\n"
  end
  
  def garbage_collector(to = $stdout)
    to.print "<h1>Garbage collector</h1>\n"
    
    if GC.enable
      to.print "<div>Garbage collector was not enabled! But it is again now!</div>\n"
    else
      to.print "<div>Garbage collector was already enabled.</div>\n"
    end
    
    GC.start
  end
  
  def hashes(to = $stdout)
    hashes = {}
    
    ObjectSpace.each_object(Hash) do |hash|
      begin
        keys_orig = hash.keys.sort
      rescue ArgumentError
        #When unable to sort regexps...
        next
      end
      
      keys = []
      keys_orig.each do |key|
        keys << key.to_s
      end
      
      if keys.empty?
        keystr = :empty
      else
        keystr = keys.join(":")
      end
      
      if !hashes.key?(keystr)
        hashes[keystr] = 1
      else
        hashes[keystr] += 1
      end
    end
    
    hashes.delete_if do |key, val|
      val < 100
    end
    
    hashes = Knj::ArrayExt.hash_sort(hashes) do |h1, h2|
      h2[1] <=> h1[1]
    end
    
    to.print "<h1>Hashes</h1>\n"
    to.write "<table class=\"hashes list\">\n"
    to.write "\t<thead>\n"
    to.write "\t\t<tr>\n"
    to.write "\t\t\t<th>Hash keys</th>\n"
    to.write "\t\t\t<th>Instances</th>\n"
    to.write "\t\t</tr>\n"
    to.write "\t</thead>\n"
    to.write"\t<tbody>\n"
    
    hashes.each do |key, val|
      to.write "\t\t<tr>\n"
      to.write "\t\t\t<td>#{Knj::Web.html(key)}</td>\n"
      to.write "\t\t\t<td>#{Knj::Locales.number_out(val, 0)}</td>\n"
      to.write "\t\t</tr>\n"
    end
    
    to.write "\t</tbody>\n"
    to.write "</table>\n"
  end
  
  def arrays(to = $stdout)
    arrays = {}
    
    ObjectSpace.each_object(Array) do |arr|
      begin
        arr = arr.sort
      rescue ArgumentError
        #When unable to sort regexps...
        next
      end
      
      keys = []
      arr.each do |key|
        keys << key.class.name.to_s
      end
      
      if keys.empty?
        keystr = :empty
      else
        keystr = keys.join(":")
      end
      
      if !arrays.key?(keystr)
        arrays[keystr] = 1
      else
        arrays[keystr] += 1
      end
    end
    
    arrays.delete_if do |key, val|
      val < 100
    end
    
    arrays = Knj::ArrayExt.hash_sort(arrays) do |h1, h2|
      h2[1] <=> h1[1]
    end
    
    to.write "<h1>Arrays</h1>\n"
    to.write "<table class=\"arrays list\">\n"
    to.write "\t<thead>\n"
    to.write "\t\t<tr>\n"
    to.write "\t\t\t<th>Array classes</th>\n"
    to.write "\t\t\t<th>Instances</th>\n"
    to.write "\t\t</tr>\n"
    to.write "\t</thead>\n"
    to.write"\t<tbody>\n"
    
    arrays.each do |key, val|
      to.write "\t\t<tr>\n"
      to.write "\t\t\t<td>#{Knj::Web.html(key)}</td>\n"
      to.write "\t\t\t<td>#{Knj::Locales.number_out(val, 0)}</td>\n"
      to.write "\t\t</tr>\n"
    end
    
    to.write "\t</tbody>\n"
    to.write "</table>\n"
  end
  
  def global_vars(to = $stdout)
    to.print "<h1>Global variables</h1>\n"
    to.print "<table class=\"global_variables list\">\n"
    to.print "\t<thead>\n"
    to.print "\t\t<tr>\n"
    to.print "\t\t\t<th>Name</th>\n"
    to.print "\t\t</tr>\n"
    to.print "\t</thead>\n"
    to.print "\t<tbody>\n"
    
    count = 0
    Kernel.global_variables.each do |name|
      count += 1
      
      #begin
      #  global_var_ref = eval(name.to_s)
      #rescue => e
      #  to.print "\t\t<tr>\n"
      #  to.print "\t\t\t<td>Error: #{Knj::Web.html(e.message)}</td>\n"
      #  to.print "\t\t</tr>\n"
      #  
      #  next
      #end
      
      #size = 0
      #size = Knj::Memory_analyzer::Object_size_counter.new(global_var_ref).calculate_size
      #size = size.to_f / 1024.0
      
      to.print "\t\t<tr>\n"
      to.print "\t\t\t<td>#{Knj::Web.html(name)}</td>\n"
      to.print "\t\t</tr>\n"
    end
    
    if count <= 0
      to.print "\t\t<tr>\n"
      to.print "\t\t\t<td colspan=\"2\" class=\"error\">No global variables has been defined.</td>\n"
      to.print "\t\t</tr>\n"
    end
    
    to.print "\t</tbody>\n"
    to.print "</table>\n"
  end
  
  def constants(to = $stdout)
    to.print "<h1>Constants</h1>\n"
    to.print "<table class=\"memory_analyzer list\">\n"
    to.print "\t<thead>\n"
    to.print "\t\t<tr>\n"
    to.print "\t\t\t<th>Class</th>\n"
    to.print "\t\t\t<th style=\"text-align: right;\">Instances</th>\n"
    to.print "\t\t</tr>\n"
    to.print "\t</thead>\n"
    to.print "\t<tbody>\n"
    
    constants_m = Module.constants
    constants_o = Object.constants
    constants_k = Kernel.constants
    constants = constants_m + constants_o + constants_k
    
    constants.sort.each do |mod|
      self.write_constant(to, Kernel, mod)
    end
    
    to.print "\t</tbody>\n"
    to.print "</table>\n"
  end
  
  def write_constant(to, mod, submod)
    submod_s = submod.to_s
    
    #return false if mod.name.to_s == "Object" or mod.name.to_s == "Module"
    return false if @printed.key?(submod_s)
    return false if mod.autoload?(submod)
    return false if !mod.const_defined?(submod)
    
    @printed[submod_s] = true
    
    instances = 0
    
    invalid_submod_size_names = ["BasicObject", "Kernel", "Object", "FALSE"]
    
    if invalid_submod_size_names.index(submod_s) != nil
      size = "-"
      calc_size = false
    else
      size = 0
      calc_size = true
    end
    
    classobj = mod.const_get(submod)
    
    begin
      ObjectSpace.each_object(classobj) do |obj|
        instances += 1
      end
    rescue Exception => e
      emsg = e.message.to_s
      if emsg.index("no such file to load") != nil or emsg.index("class or module required") != nil or emsg.index("uninitialized constant") != nil
        #return false
      else
        raise e
      end
    end
    
    if mod.to_s == "Kernel" or mod.to_s == "Class" or mod.to_s == "Object"
      mod_title = submod_s
    else
      mod_title = "#{mod.to_s}::#{submod_s}"
    end
    
    if instances > 0
      to.print "\t\t<tr>\n"
      to.print "\t\t\t<td>#{mod_title.html}</td>\n"
      to.print "\t\t\t<td style=\"text-align: right;\">#{Knj::Locales.number_out(instances, 0)}</td>\n"
      to.print "\t\t</tr>\n"
      GC.start
    end
    
    if classobj.respond_to?("constants")
      classobj.constants.sort.each do |subsubmod|
        self.write_constant(to, classobj, subsubmod)
      end
    end
  end
end

class Knj::Memory_analyzer::Object_size_counter
  def initialize(obj)
    @checked = {}
    @object = obj
  end
  
  def calculate_size
    ret = self.var_size(@object)
    @checked = nil
    @object = nil
    return ret
  end
  
  def object_size(obj)
    size = 0
    
    obj.instance_variables.each do |var_name|
      var = obj.instance_variable_get(var_name)
      next if @checked.key?(var.__id__)
      @checked[var.__id__] = true
      size += self.var_size(var)
    end
    
    return size
  end
  
  def var_size(var)
    size = 0
    
    if var.is_a?(String)
      size += var.length
    elsif var.is_a?(Integer)
      size += var.to_s.length
    elsif var.is_a?(Symbol) or var.is_a?(Fixnum)
      size += 4
    elsif var.is_a?(Time)
      size += var.to_f.to_s.length
    elsif var.is_a?(Hash)
      var.each do |key, val|
        size += self.var_size(key)
        size += self.var_size(val)
      end
    elsif var.is_a?(Array)
      var.each do |val|
        size += self.object_size(val)
      end
    elsif var.is_a?(TrueClass) or var.is_a?(FalseClass)
      size += 1
    else
      size += self.object_size(var)
    end
    
    return size
  end
end