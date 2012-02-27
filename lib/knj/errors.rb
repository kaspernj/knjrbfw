module Knj::Errors
  class Notice < StandardError; end
  class NotFound < StandardError; end
  class InvalidData < StandardError; end
  class Retry < StandardError; end
  class NoAccess < StandardError; end
  class Exists < StandardError; end
  
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