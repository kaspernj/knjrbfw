#!/usr/bin/env ruby1.9.1

Dir.chdir(File.dirname(__FILE__))
require "../../knjrbfw"
require "knj/process"
require "knj/process_meta"
require "knj/strings"

objects = {}
@process = Knj::Process.new(
  :out => $stdout,
  :in => $stdin,
  :listen => true,
  :debug => false,
  :on_rec => proc{|d, &block|
    obj = d.obj
    block_res = nil
    
    if obj.is_a?(Hash) and obj.key?("args")
      obj["args"] = Knj::Process_meta.args_parse_back(obj["args"], objects)
    end
    
    if obj.is_a?(Hash)
      if obj["type"] == "spawn_object"
        raise "An object by that name already exists: '#{obj["var_name"]}'." if objects.key?(obj["var_name"])
        
        #Fix new integer.
        if obj["class_name"].to_s == "Integer" or obj["class_name"].to_s == "Fixnum"
          objects[obj["var_name"]] = obj["args"].first.to_i
        elsif obj["class_name"].to_s == "{}" and obj["args"].first.is_a?(Hash)
          objects[obj["var_name"]] = obj["args"].first
        else
          class_obj = Knj::Strings.const_get_full(obj["class_name"])
          objects[obj["var_name"]] = class_obj.new(*obj["args"])
        end
        
        d.answer("type" => "success")
      elsif obj["type"] == "proxy_from_call"
        raise "No 'var_name' was given in arguments." if !obj["var_name"]
        raise "No object by that name when trying to do 'proxy_from_call': '#{obj["proxy_obj"]}' in '#{objects}'." if !objects.key?(obj["proxy_obj"])
        obj_to_call = objects[obj["proxy_obj"]]
        res = obj_to_call.__send__(obj["method_name"], *obj["args"])
        objects[obj["var_name"]] = res
        
        d.answer("type" => "success")
      elsif obj["type"] == "proxy_from_eval"
        res = eval(obj["str"])
        objects[obj["var_name"]] = res
        d.answer("type" => "success")
      elsif obj["type"] == "proxy_from_static"
        const = Knj::Strings.const_get_full(obj["const"])
        res = const.__send__(obj["method_name"], *obj["args"])
        objects[obj["var_name"]] = res
        d.answer("type" => "success")
      elsif obj["type"] == "call_object"
        raise "Invalid var-name: '#{obj["var_name"]}'." if obj["var_name"].to_s.strip.length <= 0
        
        obj_to_call = objects[obj["var_name"]]
        raise "No object by that name: '#{obj["var_name"]}'." if !obj
        res = obj_to_call.__send__(obj["method_name"], *obj["args"])
        res = nil if obj["capture_return"] == false
        d.answer("type" => "call_object_success", "result" => res)
      elsif obj["type"] == "call_object_buffered"
        raise "Invalid var-name: '#{obj["var_name"]}'." if obj["var_name"].to_s.strip.length <= 0
        
        obj_to_call = objects[obj["var_name"]]
        raise "No object by that name: '#{obj["var_name"]}'." if !obj
        capt_return = obj["capture_return"]
        
        if capt_return != false
          ret = []
        else
          ret = nil
        end
        
        obj["args"].each do |args|
          if capt_return != false
            ret << obj_to_call.__send__(obj["method_name"], *args)
          else
            obj_to_call.__send__(obj["method_name"], *args)
          end
        end
        
        d.answer("type" => "call_object_success", "result" => res)
      elsif obj["type"] == "call_object_block"
        raise "Invalid var-name: '#{obj["var_name"]}'." if obj["var_name"].to_s.strip.length <= 0
        res = nil
        
        begin
          raise Knj::Errors::NotFound, "No object by that name: '#{obj["var_name"]}' in '#{objects}'." if !objects.key?(obj["var_name"])
          obj_to_call = objects[obj["var_name"]]
          raise "No object by that name: '#{obj["var_name"]}'." if !obj
          
          res = obj_to_call.__send__(obj["method_name"], *obj["args"]) do |*args|
            block_res = block.call(*args) if block
          end
        ensure
          #This has to be ensured, because this block wont be runned any more after enumerable has been broken...
          res = nil if obj["capture_return"] == false
          d.answer("type" => "call_object_success", "result" => res)
        end
      elsif obj["type"] == "unset"
        raise "Invalid var-name: '#{obj["var_name"]}'." if obj["var_name"].to_s.strip.length <= 0
        raise Knj::Errors::NotFound, "Var-name didnt exist when trying to unset: '#{obj["var_name"]}'." if !objects.key?(obj["var_name"])
        objects.delete(obj["var_name"])
        d.answer("type" => "unset_success")
      elsif obj["type"] == "unset_multiple"
        err = nil
        obj["var_names"].each do |var_name|
          err = [Knj::Errors::InvalidData, "Invalid var-name: '#{var_name}'."] if var_name.to_s.strip.length <= 0
          err = [Knj::Errors::NotFound, "Var-name didnt exist when trying to unset: '#{var_name}'."] if !objects.key?(var_name)
          objects.delete(var_name)
        end
        
        raise err[0], err[1] if err
        d.answer("type" => "unset_success")
      elsif obj["type"] == "static"
        const = Knj::Strings.const_get_full(obj["const"])
        res = const.__send__(obj["method_name"], *obj["args"], &block)
        res = nil if obj["capture_return"] == false
        d.answer("type" => "call_const_success", "result" => res)
      elsif obj["type"] == "str_eval"
        res = eval(obj["str"])
        d.answer("type" => "call_eval_success", "result" => res)
      elsif obj["type"] == "exit"
        d.answer("type" => "exit_success")
        sleep 0.1
        @process.destroy
        exit
      elsif obj["type"] == "process_data"
        d.answer("type" => "process_data_success", "pid" => Process.pid)
      else
        raise "Didnt know how to handle hash: '#{Knj::Php.print_r(obj, true)}'."
      end
    else
      raise "Unknown object: '#{obj.class.name}'."
    end
    
    block_res
  }
)

print "process_meta_started\n"
@process.join