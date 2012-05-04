#This module contains various extra errors used by the other Knj-code.
module Knj::Errors
  #An error that is used when the error is just a notice.
  class Notice < StandardError; end
  
  #Typically used when an object is not found by the given arguments.
  class NotFound < StandardError; end
  
  #If invalid data was supplied to a list-method or something like it.
  class InvalidData < StandardError; end
  
  #An error that specifies that the caller should retry the operation.
  class Retry < StandardError; end
  
  #The current env does not have access to calling the method.
  class NoAccess < StandardError; end
  
  #The thing you are trying to add already exists or have already been done.
  class Exists < StandardError; end
  
  #Returns a string describing the given error. Possible arguments can be given if you want the returned string formatted as HTML.
  #
  #===Examples
  # begin
  #   raise 'test'
  # rescue => e
  #   print Knj::Errors.error_str(e, :html => true)
  # end
  def self.error_str(err, args = {})
    if !err.is_a?(Exception) and err.class.message != "Java::JavaLang::LinkageError"
      raise "Invalid object of class '#{err.class.name}' given."
    end
    
    str = ""
    
    if args[:html]
      str << "<b>#{err.class.name}</b>: #{err.message}<br />\n<br />\n"
      str << err.backtrace.join("<br />\n")
    else
      str << "#{err.class.name}: #{err.message}\n\n"
      str << err.backtrace.join("\n")
    end
    
    return str
  end
end