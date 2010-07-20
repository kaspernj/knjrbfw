$knjpath = File.dirname(__FILE__) + "/"

module Knj
	autoload :ArrayExt, $knjpath + "arrayext"
	autoload :Db, $knjpath + "knjdb/libknjdb"
	autoload :Db_row, $knjpath + "knjdb/libknjdb_row"
	autoload :Errors, $knjpath + "errors"
	autoload :Objects, $knjpath + "objects"
	autoload :Opts, $knjpath + "opts"
	autoload :Mail, $knjpath + "mail"
	autoload :Notify, $knjpath + "notify"
	autoload :Web, $knjpath + "web"
	autoload :Datestamp, $knjpath + "datestamp"
	autoload :Http, $knjpath + "http"
	autoload :Sms, $knjpath + "sms"
	autoload :Os, $knjpath + "os"
	autoload :Gtk2, $knjpath + "gtk2"
	autoload :Php, $knjpath + "php"
	autoload :Strings, $knjpath + "strings"
	autoload :SSHRobot, $knjpath + "sshrobot/sshrobot"
	autoload :Sysuser, $knjpath + "sysuser"
	autoload :Thread, $knjpath + "thread"
	autoload :Unix_proc, $knjpath + "unix_proc"
end

#ruby objects.
autoload :CGI, "cgi"
autoload :Date, "date"
autoload :Digest, "digest"
autoload :Erubis, "erubis"
autoload :FileUtils, "fileutils"
autoload :Mysql, "mysql"
autoload :ParseDate, "parsedate"
autoload :SQLite3, "sqlite3"
autoload :Ping, "ping"
autoload :SOAP, "knj/autoload/soap"
autoload :TCPSocket, "socket"
autoload :TCPServer, "socket"
autoload :XmlSimple, "xmlsimple"

if RUBY_PLATFORM == "java"
	autoload :GetText, "gettext"
	autoload :Gtk, "knj/jruby-gtk2/gtk2"
	autoload :Gdk, "knj/jruby-gtk2/gtk2"
	autoload :GladeXML, "knj/jruby-gtk2/gtk2"
elsif RUBY_PLATFORM.index("mswin32") != nil
	autoload :GetText, "knj/gettext_fallback"
	autoload :Gtk, "knj/ironruby-gtk2/gtk2"
	autoload :Gdk, "knj/ironruby-gtk2/gtk2"
	autoload :GladeXML, "knj/ironruby-gtk2/gtk2"
else
	autoload :GetText, "gettext"
	autoload :Gtk, "gtk2"
	autoload :Gdk, "gtk2"
	autoload :GladeXML, "libglade2"
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
	autoload :Mail, "tmail"
end

#facets
autoload :Dictionary, "facets/dictionary.rb"

#gems
autoload :Twitter, $knjpath + "autoload/twitter"
autoload :Facebooker, $knjpath + "autoload/facebooker"
autoload :Cinch, $knjpath + "autoload/cinch"