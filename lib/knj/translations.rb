class Knj::Translations
  attr_accessor :args, :db, :ob, :cache
  
  def initialize(args)
    @args = args
    
    raise "No DB given." if !@args[:db]
    @db = @args[:db]
    
    @ob = Knj::Objects.new(
      :db => @args[:db],
      :extra_args => [self],
      :class_path => File.dirname(__FILE__),
      :module => Knj::Translations,
      :require => false,
      :datarow => true
    )
  end
  
  #Returns the translated value for an object by the given key.
  def get(obj, key, args = {})
    return "" if !obj
    
    if args[:locale]
      locale = args[:locale].to_sym
    else
      locale = @args[:locale].to_sym
    end
    
    #Force to symbol to save memory when caching.
    key = key.to_sym
    
    #Set-get the cache-hash for the object.
    if !obj.instance_variable_defined?("@knj_translations_cache")
      obj.instance_variable_set("@knj_translations_cache", {})
    end
    
    cache = obj.instance_variable_get("@knj_translations_cache")
    
    #Return from cache if set.
    if cache.key?(key) and cache[key].key?(locale)
      return cache[key][locale]
    end
    
    trans = @ob.list(:Translation, {
      "object_class" => obj.class.name,
      "object_id" => obj.id,
      "key" => key,
      "locale" => locale
    })
    
    if trans.empty?
      print "Nothing found - returning empty string.\n" if @args[:debug] or args[:debug]
      return ""
    end
    
    trans.each do |tran|
      if !cache[key]
        cache[key] = {
          locale => tran[:value]
        }
      elsif !cache[key][locale]
        cache[key][locale] = tran[:value]
      end
    end
    
    return cache[key][locale]
  end
  
  #Sets translations for an object by the given hash-keys and hash-values.
  def set(obj, values, args = {})
    if args[:locale]
      locale = args[:locale]
    else
      locale = @args[:locale]
    end
    
    values.each do |key, val|
      trans = @ob.get_by(:Translation, {
        "object_id" => obj.id,
        "object_class" => obj.class.name,
        "key" => key,
        "locale" => locale
      })
      
      if trans
        trans.update(:value => val)
      else
        @ob.add(:Translation, {
          :object => obj,
          :key => key,
          :locale => locale,
          :value => val
        })
      end
    end
  end
  
  #Deletes all translations for a given object.
  def delete(obj)
    classn = obj.class.name
    objid = obj.id.to_s
    
    if obj.instance_variable_defined?("@knj_translations_cache")
      cache = obj.instance_variable_get("@knj_translations_cache")
    end
    
    trans = @ob.list(:Translation, {
      "object_id" => obj.id,
      "object_class" => obj.class.name
    })
    trans.each do |tran|
      #Delete the translation object.
      @ob.delete(tran)
      
      #Delete the cache if defined on the object.
      cache.delete(tran[:key].to_sym) if cache and cache.key?(tran[:key].to_sym)
    end
  end
end

class Knj::Translations::Translation < Knj::Datarow
  def self.add(d)
    if d.data[:object]
      d.data[:object_class] = d.data[:object].class.name
      d.data[:object_id] = d.data[:object].id
      d.data.delete(:object)
    end
  end
end