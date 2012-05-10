$knjpath = File.dirname(__FILE__) + "/" if !$knjpath
require "#{$knjpath}/knj"

module Knj
  autoload :Db_row, $knjpath + "knjdb/libknjdb_row"
  autoload :Fs, $knjpath + "fs/fs"
  autoload :Php_parser, $knjpath + "php_parser/php_parser"
  autoload :SSHRobot, $knjpath + "sshrobot/sshrobot"
end

#ruby objects.
autoload :Base64, "base64"
autoload :CGI, "cgi"
autoload :CSV, "csv"
autoload :Date, "date"
autoload :Digest, "digest"
autoload :Erubis, $knjpath + "autoload/erubis"
autoload :EM, "eventmachine"
autoload :FCGI, "fcgi"
autoload :FileUtils, "fileutils"
autoload :IPAddr, "ipaddr"
autoload :JSON, $knjpath + "autoload/json"
autoload :GD2, $knjpath + "autoload/gd2"
autoload :Magick, $knjpath + "autoload/magick"
autoload :Monitor, "monitor"
autoload :Mutex, "thread"
autoload :Mysql, $knjpath + "autoload/mysql"
autoload :Open3, "open3"
autoload :OpenSSL, "openssl"
autoload :OptionParser, "optparse"
autoload :ParseDate, $knjpath + "autoload/backups/parsedate"
autoload :Pathname, "pathname"
autoload :Ping, $knjpath + "autoload/ping"
autoload :REXML, $knjpath + "autoload/rexml"
autoload :StringIO, "stringio"
autoload :SOAP, $knjpath + "autoload/soap"
autoload :SQLite3, $knjpath + "autoload/sqlite3"
autoload :Timeout, "timeout"
autoload :TCPSocket, "socket"
autoload :TCPServer, "socket"
autoload :TZInfo, $knjpath + "autoload/tzinfo"
autoload :URI, "uri"
autoload :Win32, "win32/registry"
autoload :WIN32OLE, "win32ole"
autoload :WeakRef, "weakref"
autoload :WEBrick, "webrick"
autoload :XmlSimple, $knjpath + "autoload/xmlsimple"
autoload :Zip, $knjpath + "autoload/zip"
autoload :Zlib, "zlib"

if RUBY_PLATFORM == "java"
  autoload :GetText, $knjpath + "autoload/gettext"
  autoload :Gtk, "knj/jruby-gtk2/gtk2"
  autoload :Gdk, "knj/jruby-gtk2/gtk2"
  autoload :GladeXML, "knj/jruby-gtk2/gtk2"
elsif RUBY_PLATFORM.index("mswin32") != nil
  autoload :GetText, "knj/gettext_fallback"
  autoload :Gtk, "knj/ironruby-gtk2/gtk2"
  autoload :Gdk, "knj/ironruby-gtk2/gtk2"
  autoload :GladeXML, "knj/ironruby-gtk2/gtk2"
else
  autoload :GetText, $knjpath + "autoload/gettext"
  autoload :Gtk, $knjpath + "autoload/gtk2"
  autoload :GladeXML, "libglade2"
  
  #this bugs?
  #autoload :Gdk, $knjpath + "autoload/gtk2"
end

module Net
  autoload :IMAP, "net/imap"
  autoload :SMTP, "net/smtp"
  autoload :HTTP, "net/http"
  autoload :POP3, "net/pop"
  autoload :POP, "net/pop"
  autoload :SSH, "net/ssh"
end

module TMail
  autoload :Mail, $knjpath + "autoload/tmail"
end

#facets
autoload :Dictionary, $knjpath + "autoload/facets_dictionary"

#gems
autoload :ActiveSupport, $knjpath + "autoload/activesupport"
autoload :Cinch, $knjpath + "autoload/cinch"
autoload :Facebooker, $knjpath + "autoload/facebooker"
autoload :Tsafe, "tsafe"
autoload :Wref, "wref"
autoload :Wref_map, "wref"