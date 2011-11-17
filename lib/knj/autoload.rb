$knjpath = File.dirname(__FILE__) + "/" if !$knjpath
require "#{$knjpath}/knj"

module Knj
  autoload :Amixer, $knjpath + "amixer"
	autoload :ArrayExt, $knjpath + "arrayext"
	autoload :Datestamp, $knjpath + "datestamp"
	autoload :Datet, $knjpath + "datet"
	autoload :Cmd_gen, $knjpath + "cmd_gen"
	autoload :Cmd_parser, $knjpath + "cmd_parser"
	autoload :Compiler, $knjpath + "compiler"
	autoload :Cpufreq, $knjpath + "cpufreq"
	autoload :Datarow, $knjpath + "datarow"
	autoload :Db, $knjpath + "knjdb/libknjdb"
	autoload :Db_row, $knjpath + "knjdb/libknjdb_row"
	autoload :Degulesider, $knjpath + "degulesider"
	autoload :Errors, $knjpath + "errors"
	autoload :Eruby, $knjpath + "eruby"
	autoload :Event_filemod, $knjpath + "event_filemod"
	autoload :Event_handler, $knjpath + "event_handler"
	autoload :Exchangerates, $knjpath + "exchangerates"
	autoload :Facebook_connect, $knjpath + "facebook_connect"
	autoload :Fs, $knjpath + "fs/fs"
	autoload :Filesystem, $knjpath + "filesystem"
	autoload :Gettext_threadded, $knjpath + "gettext_threadded"
	autoload :Hash_methods, $knjpath + "hash_methods"
	autoload :Http, $knjpath + "http"
	autoload :Http2, $knjpath + "http2"
	autoload :Image, $knjpath + "image"
	autoload :Ip2location, $knjpath + "ip2location"
	autoload :Jruby_compiler, $knjpath + "jruby_compiler"
	autoload :Locales, $knjpath + "locales"
	autoload :Objects, $knjpath + "objects"
	autoload :Opts, $knjpath + "opts"
	autoload :Mail, $knjpath + "mail"
	autoload :Mailobj, $knjpath + "mailobj"
	autoload :Mutexcl, $knjpath + "mutexcl"
	autoload :Mount, $knjpath + "mount"
	autoload :Mplayer, $knjpath + "mplayer"
	autoload :Notify, $knjpath + "notify"
	autoload :Nvidia_settings, $knjpath + "nvidia_settings"
	autoload :Web, $knjpath + "web"
	autoload :Google_sitemap, $knjpath + "google_sitemap"
	autoload :Sms, $knjpath + "sms"
	autoload :Os, $knjpath + "os"
	autoload :Gtk2, $knjpath + "gtk2"
	autoload :Php, $knjpath + "php"
	autoload :Php_parser, $knjpath + "php_parser/php_parser"
	autoload :Power_manager, $knjpath + "power_manager"
	autoload :Rand, $knjpath + "rand"
	autoload :Retry, $knjpath + "retry"
	autoload :RSVGBIN, $knjpath + "rsvgbin"
	autoload :Strings, $knjpath + "strings"
	autoload :SSHRobot, $knjpath + "sshrobot/sshrobot"
	autoload :Sysuser, $knjpath + "sysuser"
	autoload :Thread, $knjpath + "thread"
	autoload :Thread2, $knjpath + "thread2"
	autoload :Threadpool, $knjpath + "threadpool"
	autoload :Threadhandler, $knjpath + "threadhandler"
	autoload :Translations, $knjpath + "translations"
	autoload :X11VNC, $knjpath + "x11vnc"
	autoload :Unix_proc, $knjpath + "unix_proc"
	autoload :YouTube, $knjpath + "youtube"
	autoload :Win, $knjpath + "win"
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
autoload :JSON, $knjpath + "autoload/json_autoload"
autoload :GD2, $knjpath + "autoload/gd2"
autoload :Magick, $knjpath + "autoload/magick"
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
autoload :Twitter, $knjpath + "autoload/twitter"
autoload :Facebooker, $knjpath + "autoload/facebooker"
autoload :Cinch, $knjpath + "autoload/cinch"
autoload :ActiveSupport, $knjpath + "autoload/activesupport"
