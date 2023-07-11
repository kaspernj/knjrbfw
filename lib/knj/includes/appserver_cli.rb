require "knj/autoload"
require "#{$knjpath}web"

class Appserver_cli
  def self.loadfile(filepath)
    require filepath
  end

  def self._(str)
    return str
  end

  def self.gettext
    return self
  end

  def self.lang_opts
    return []
  end
end

def _kas
  return Appserver_cli
end

def _db
  return $db
end

def _ob
  return $ob
end

autoinc_cli_path = "../include/autoinclude_cli.rb"
if File.exist?(autoinc_cli_path)
  require autoinc_cli_path
else
  require "../include/autoinclude.rb"
end