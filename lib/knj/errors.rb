#This module contains various extra errors used by the other Knj-code.
module Knj::Errors
  #An error that is used when the error is just a notice.
  class Notice < StandardError; end
  
  #An error that specifies that the caller should retry the operation.
  class Retry < StandardError; end
  
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
      str << "<b>#{Knj::Web.html(err.class.name)}</b>: #{Knj::Web.html(err.message)}<br />\n<br />\n"
      
      err.backtrace.each do |bt|
        str << "#{Knj::Web.html(bt)}<br />\n"
      end
      
      str << "<br />\n<br />\n"
    else
      str << "#{err.class.name}: #{err.message}\n\n"
      str << err.backtrace.join("\n")
      str << "\n\n"
    end
    
    return str
  end
end