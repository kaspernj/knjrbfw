module Knj::Errors
  class Notice < StandardError; end
  class NotFound < StandardError; end
  class InvalidData < StandardError; end
  class Retry < StandardError; end
  class NoAccess < StandardError; end
  class Exists < StandardError; end
  
  def self.error_str(err, args = {})
    raise "Invalid object of class '#{err.class.name}' given." if !err.is_a?(Exception)
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