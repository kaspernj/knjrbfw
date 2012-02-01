#!/usr/bin/env ruby1.9.1

Dir.chdir(File.dirname(__FILE__))
require "../../knjrbfw"
require "knj/process"
require "knj/autoload"

objects = {}
@process = Knj::Process.new(
  :out => $stdout,
  :in => $stdin,
  :listen => true,
  :debug => false,
  :on_rec => proc{|d|
    obj = d.obj
    
    if obj.is_a?(Hash)
      if obj["type"] == "spawn_object"
        class_obj = Knj::Strings.const_get_full(obj["class_name"])
        objects[obj["var_name"]] = class_obj.new(*obj["args"])
        d.answer("type" => "success")
      elsif obj["type"] == "call_object"
        raise "Invalid var-name: '#{obj["var_name"]}'." if obj["var_name"].to_s.strip.length <= 0
        
        obj_to_call = objects[obj["var_name"]]
        raise "No object by that name: '#{obj["var_name"]}'." if !obj
        res = obj_to_call.send(obj["method_name"], *obj["args"])
        d.answer("type" => "call_object_success", "result" => res)
      elsif obj["type"] == "unset"
        raise "Invalid var-name: '#{obj["var_name"]}'." if obj["var_name"].to_s.strip.length <= 0
        raise "Var-name doesnt exist: '#{obj["var_name"]}'." if !objects.key?(obj["var_name"])
        objects.delete(obj["var_name"])
        d.answer("type" => "unset_success")
      elsif obj["type"] == "exit"
        d.answer("type" => "exit_success")
        exit
      else
        raise "Didnt know how to handle hash: '#{Knj::Php.print_r(obj, true)}'."
      end
    else
      raise "Unknown object: '#{obj.class.name}'."
    end
  }
)
@process.join