class Knj::Memory_analyzer
  def initialize
    @printed = {}
  end
  
  def write(to = $stdout)
    to.print "<table class=\"memory_analyzer list\">"
    to.print "<thead>"
    to.print "<tr>"
    to.print "<th>Class</th>"
    to.print "<th style=\"text-align: right;\">Instances</th>"
    to.print "<th style=\"text-align: right;\">Size</th>"
    to.print "</tr>"
    to.print "</thead>"
    to.print "<tbody>"
    
    constants_m = Module.constants
    constants_o = Object.constants
    constants_k = Kernel.constants
    constants = constants_m + constants_o + constants_k
    
    constants.sort.each do |mod|
      self.write_constant(to, Kernel, mod)
    end
    
    to.print "</tbody>"
    to.print "</table>"
  end
  
  def write_constant(to, mod, submod)
    submod_s = submod.to_s
    
    #return false if mod.name.to_s == "Object" or mod.name.to_s == "Module"
    return false if @printed.key?(submod_s)
    return false if mod.autoload?(submod)
    return false if !mod.const_defined?(submod)
    
    @printed[submod_s] = true
    
    instances = 0
    size = 0
    classobj = mod.const_get(submod)
    
    begin
      ObjectSpace.each_object(classobj) do |obj|
        instances += 1
        
        size += Knj::Memory_analyzer::Object_size_counter.new(obj).calculate_size
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
      size_kb = size.to_f / 1024.0
      
      to.print "<tr>"
      to.print "<td>#{mod_title.html}</td>"
      to.print "<td style=\"text-align: right;\">#{Knj::Locales.number_out(instances, 0)}</td>"
      to.print "<td style=\"text-align: right;\">#{Knj::Locales.number_out(size_kb, 2)} kb</td>"
      to.print "</tr>"
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
    ret = self.object_size(@object)
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
      
      if var.is_a?(String)
        size += var.length
      elsif var.is_a?(Integer)
        size += var.to_s.length
      elsif var.is_a?(Symbol) or var.is_a?(Fixnum)
        size += 4
      elsif var.is_a?(Hash)
        var.each do |key, val|
          size += self.object_size(key)
          size += self.object_size(val)
        end
      elsif var.is_a?(Array)
        var.each do |val|
          size += self.object_size(val)
        end
      elsif var == true or var == false
        size += 1
      else
        size += self.object_size(var)
      end
    end
    
    return size
  end
end