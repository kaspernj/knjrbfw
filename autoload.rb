$knjpath = File.dirname(__FILE__) + "/"

module Knj
	autoload :ArrayExt, $knjpath + "arrayext"
	autoload :Datestamp, $knjpath + "datestamp"
	autoload :Datet, $knjpath + "datet"
	autoload :Db, $knjpath + "knjdb/libknjdb"
	autoload :Db_row, $knjpath + "knjdb/libknjdb_row"
	autoload :Degulesider, $knjpath + "degulesider"
	autoload :Errors, $knjpath + "errors"
	autoload :Locales, $knjpath + "locales"
	autoload :Objects, $knjpath + "objects"
	autoload :Opts, $knjpath + "opts"
	autoload :Mail, $knjpath + "mail"
	autoload :Notify, $knjpath + "notify"
	autoload :Web, $knjpath + "web"
	autoload :Google_sitemap, $knjpath + "google_sitemap"
	autoload :Http, $knjpath + "http"
	autoload :Sms, $knjpath + "sms"
	autoload :Os, $knjpath + "os"
	autoload :Gtk2, $knjpath + "gtk2"
	autoload :Php, $knjpath + "php"
	autoload :Rand, $knjpath + "rand"
	autoload :Retry, $knjpath + "retry"
	autoload :RSVGBIN, $knjpath + "rsvgbin"
	autoload :Strings, $knjpath + "strings"
	autoload :SSHRobot, $knjpath + "sshrobot/sshrobot"
	autoload :Sysuser, $knjpath + "sysuser"
	autoload :Thread, $knjpath + "thread"
	autoload :Translations, $knjpath + "translations"
	autoload :X11VNC, $knjpath + "x11vnc"
	autoload :Unix_proc, $knjpath + "unix_proc"
	autoload :YouTube, $knjpath + "youtube"
	autoload :Win, $knjpath + "win"
end

#ruby objects.
autoload :CGI, "cgi"
autoload :CSV, "csv"
autoload :Date, "date"
autoload :Digest, "digest"
autoload :Erubis, $knjpath + "autoload/erubis"
autoload :EM, "eventmachine"
autoload :FCGI, "fcgi"
autoload :FileUtils, "fileutils"
autoload :JSON, $knjpath + "autoload/json_autoload"
autoload :GD2, $knjpath + "autoload/gd2"
autoload :Mysql, $knjpath + "autoload/mysql"
autoload :OpenSSL, "openssl"
autoload :OptionParser, "optparse"
autoload :ParseDate, $knjpath + "autoload/backups/parsedate.rb"
autoload :Pathname, "pathname"
autoload :Ping, "ping"
autoload :REXML, $knjpath + "autoload/rexml"
autoload :StringIO, "stringio"
autoload :SOAP, $knjpath + "autoload/soap"
autoload :SQLite3, "sqlite3"
autoload :Timeout, "timeout"
autoload :TCPSocket, "socket"
autoload :TCPServer, "socket"
autoload :URI, "uri"
autoload :Win32, "win32/registry"
autoload :WIN32OLE, "win32ole"
autoload :WEBrick, "webrick"
autoload :XmlSimple, "xmlsimple"
autoload :Zip, "zip/zip"

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
	autoload :Mail, "tmail"
end

#facets
autoload :Dictionary, $knjpath + "autoload/facets_dictionary"

#gems
autoload :Twitter, $knjpath + "autoload/twitter"
autoload :Facebooker, $knjpath + "autoload/facebooker"
autoload :Cinch, $knjpath + "autoload/cinch"
autoload :ActiveSupport, $knjpath + "autoload/activesupport"