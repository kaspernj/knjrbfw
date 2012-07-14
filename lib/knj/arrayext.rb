module Knj::ArrayExt
  def self.join(args = {}, key = nil, sep = nil)
    if args.is_a?(Array) and sep
      args = {
        :arr => args,
        :sep => sep,
        :key => key
      }
    end
    
    raise "No seperator given." if !args[:sep]
    
    str = ""
    first = true
    
    Knj::Php.foreach(args[:arr]) do |key, value|
      if first
        first = false
      else
        str << args[:sep]
      end
      
      if args[:key]
        value = key
      else
        value = value
      end
      
      if args[:callback]
        if args[:callback].is_a?(Proc) or args[:callback].is_a?(Method)
          value = args[:callback].call(value)
        else
          value = Knj::Php.call_user_func(args[:callback], value) if args[:callback]
        end
      end
      
      raise "Callback returned nothing." if args[:callback] and !value
      
      str << args[:surr] if args[:surr]
      str << value.to_s
      str << args[:surr] if args[:surr]
    end
    
    return str
  end
  
  #Converts an array to a hash with the index a string-numbers.
  def self.array_to_hash(arr)
    ret = {}
    arr.each do |item|
      ret[ret.length.to_s] = item
    end
    
    return ret
  end
  
  #Returns true if all keys in a hash are numeric objects.
  def self.hash_numeric_keys?(hash)
    all_num = true
    hash.each do |key, val|
      if !Knj::Php.is_numeric(key)
        all_num = false
        break
      end
    end
    
    return all_num
  end
  
  #Converts all keys in the given hash to symbols.
  def self.hash_sym(hash_given)
    raise "Invalid argument-class: '#{hash_given.class.name}'." if !hash_given or !hash_given.respond_to?(:each)
    
    adds = {}
    hash_given.each do |key, value|
      if !key.is_a?(Symbol)
        adds[key.to_sym] = value
        hash_given.delete(key)
      end
    end
    
    hash_given.merge!(adds)
    
    return hash_given
  end
  
  #Converts all keys in the given hash to strings.
  def self.hash_str(hash_given)
    adds = {}
    
    hash_given.each do |key, val|
      if !key.is_a?(String)
        adds[key.to_s] = val
        hash_given.delete(key)
      end
    end
    
    hash_given.merge!(adds)
    
    return hash_given
  end
  
  def self.dict(arr)
    ret = Dictionary.new
    arr.each do |item|
      ret[ret.length.to_s] = item
    end
    
    return ret
  end
  
  #Returns a hash based on the keys and values of a hash.
  def self.hash_md5(hash)
    combined_val = ""
    hash.each do |key, val|
      if combined_val.length > 0
        combined_val << ";"
      end
      
      combined_val << "#{key}:#{val}"
    end
    
    return Digest::MD5.hexdigest(combined_val)
  end
  
  #Compares the keys and values of two hashes and returns true if they are different.
  def self.hash_diff?(h1, h2, args = {})
    if !args.key?("h1_to_h2") or args["h1_to_h2"]
      h1.each do |key, val|
        return true if !h2.key?(key)
        
        hash_val = h2[key].to_s
        hash_val = hash_val.force_encoding("UTF-8") if hash_val.respond_to?(:force_encoding)
        
        val = val.to_s
        val = val.force_encoding("UTF-8") if val.respond_to?(:force_encoding)
        
        return true if hash_val != val
      end
    end
    
    if !args.key?("h2_to_h1") or args["h2_to_h1"]
      h2.each do |key, val|
        return true if !h1.key?(key)
        
        hash_val = h1[key].to_s
        hash_val = hash_val.force_encoding("UTF-8") if hash_val.respond_to?(:force_encoding)
        
        val = val.to_s
        val = val.force_encoding("UTF-8") if val.respond_to?(:force_encoding)
        
        return true if hash_val != val
      end
    end
    
    return false
  end
  
  #Returns a hash based on the string-keys in a hash.
  def self.hash_keys_hash(hash)
    hashes = []
    hash.keys.sort.each do |key|
      hashes << Digest::MD5.hexdigest(key.to_s)
    end
    
    return Digest::MD5.hexdigest(hashes.join("_"))
  end
  
  #Returns hash based on the string-values in a hash.
  def self.hash_values_hash(hash)
    hashes = []
    hash.keys.sort.each do |key|
      hashes << Digest::MD5.hexdigest(hash[key].to_s)
    end
    
    return Digest::MD5.hexdigest(hashes.join("_"))
  end
  
  #Returns a hash based on the string-values of an array.
  def self.array_hash(arr)
    hashes = []
    arr.each do |ele|
      hashes << Digest::MD5.hexdigest(ele.to_s)
    end
    
    return Digest::MD5.hexdigest(hashes.join("_"))
  end
  
  #Validates a hash of data.
  def self.validate_hash(h, args)
    h.each do |key, val|
      if args.key?(:not_empty) and args[:not_empty].index(key) != nil and val.to_s.strip.length <= 0
        raise ArgumentError, sprintf(args[:not_empty_error], key)
      end
    end
  end
  
  #Sorts the hash without being a retard...
  def self.hash_sort(hash, &block)
    sorted = hash.sort(&block)
    
    ret = {}
    sorted.each do |ele|
      ret[ele[0]] = ele[1]
    end
    
    return ret
  end
  
  #Forces all strings in an array or a hash to be encoded to a specific encoding recursively.
  def self.clone_encode(hash, encoding, args = {})
    return hash if !hash
    
    hash = hash.clone
    Knj::Php.foreach(hash) do |key, val|
      if val.is_a?(String)
        begin
          hash[key] = Knj::Php.utf8_encode(val)
        rescue Encoding::UndefinedConversionError => e
          if args["ignore_encoding_errors"]
            next
          else
            raise e
          end
        end
      elsif val.is_a?(Array) or val.is_a?(Hash)
        hash[key] = Knj::ArrayExt.clone_encode(val, encoding, args)
      end
    end
    
    return hash
  end
  
  #Forces an array to have a certain amount of columns.
  #===Examples
  # arr = [1, 2, 3, 4, 5]
  # Knj::ArrayExt.force_no_cols(:arr => arr, :no => 4) #=> [1, 2, 3, 4]
  def self.force_no_cols(args)
    while args[:arr].length > args[:no]
      args[:arr].slice!(-1)
    end
    
    while args[:arr].length < args[:no]
      args[:arr] << args[:empty]
    end
    
    return nil
  end
  
  #Returns a powerset of the given array. Copied from 'http://mikeburnscoder.wordpress.com/2009/05/30/powerset-in-ruby-using-the-list-monad/'.
  #===Examples
  # ps = Knj::ArrayExt.powerset(:arr => [1, 2 , 3, 4])
  # ps.length #=> 16
  def self.powerset(args)
    arr = args[:arr]
    raise "No array was given." if !arr
    
    if block_given?
      if arr.length == 0
        yield []
      else
        Knj::ArrayExt.powerset(:arr => arr[0..-2]) do |set|
          yield set
          yield set + [arr[-1]]
        end
      end
      
      arr
    else
      Enumerator.new do |sets|
        Knj::ArrayExt.powerset(:arr => arr) do |set|
          sets << set
        end
      end
    end
  end
  
  #Divides an array based on callback.
  #===Examples
  # arr = [1, 2, 3, 4, 6, 7, 8, 9, 15, 16, 17, 18]
  # res = Knj::ArrayExt.divide(:arr => arr) do |a, b|
  #   if (b - a) > 1
  #     false
  #   else
  #     true
  #   end
  # end
  # 
  # res.length #=> 3
  def self.divide(args, &block)
    prev_ele = args[:arr].shift
    chunk = [prev_ele]
    
    if !args[:evaluate]
      callback_eval = block
    elsif !args[:callback] and args[:evaluate]
      callback_res = block
      callback_eval = args[:evaluate]
    end
    
    ret = [] if !args[:callback]
    
    args[:arr].each do |ele|
      if !chunk
        chunk = [ele]
        prev_ele = ele
        next
      end
      
      if callback_eval.call(prev_ele, ele)
        chunk << ele
      elsif callback_res
        callback_res.call(chunk)
        chunk = nil
      else
        ret << chunk
        chunk = nil
      end
      
      prev_ele = ele
    end
    
    if chunk and !chunk.empty?
      if callback_res
        callback_res.call(chunk)
      else
        ret << chunk
      end
    end
    
    if args[:callback]
      return nil
    else
      return ret
    end
  end
  
  #Returns a given hash in an array by mathing the contents up against another hash.
  def self.array_hash_find(args)
    args[:arr].each do |h|
      found = true
      
      args[:args].each do |key, val|
        if h[key] != val
          found = false
          break
        end
      end
      
      return h if found
    end
    
    return nil
  end
end