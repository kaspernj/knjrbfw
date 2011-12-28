require "rexml/rexml"

module REXML
  autoload :Document, "rexml/document"
  autoload :ParseException, "rexml/parseexception"
end

module REXML::Formatters
  autoload :Default, "rexml/formatters/default"
  autoload :Pretty, "rexml/formatters/pretty"
  autoload :Transitive, "rexml/formatters/transitive"
end