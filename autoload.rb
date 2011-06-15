$knjpath = File.dirname(__FILE__) + "/" if !$knjpath
require "#{$knjpath}/knj.rb"

module Knj
	autoload :ArrayExt, $knjpath + "arrayext.rb"
	autoload :Datestamp, $knjpath + "datestamp.rb"
	autoload :Datet, $knjpath + "datet.rb"
	autoload :Cpufreq, $knjpath + "cpufreq.rb"
	autoload :Datarow, $knjpath + "datarow.rb"
	autoload :Db, $knjpath + "knjdb/libknjdb.rb"
	autoload :Db_row, $knjpath + "knjdb/libknjdb_row.rb"
	autoload :Degulesider, $knjpath + "degulesider.rb"
	autoload :Errors, $knjpath + "errors.rb"
	autoload :Eruby, $knjpath + "eruby.rb"
	autoload :Event_filemod, $knjpath + "event_filemod.rb"
	autoload :Event_handler, $knjpath + "event_handler.rb"
	autoload :Exchangerates, $knjpath + "exchangerates.rb"
	autoload :Fs, $knjpath + "fs/fs.rb"
	autoload :Gettext_threadded, $knjpath + "gettext_threadded.rb"
	autoload :Hash_methods, $knjpath + "hash_methods.rb"
	autoload :Ip2location, $knjpath + "ip2location.rb"
	autoload :Jruby_compiler, $knjpath + "jruby_compiler.rb"
	autoload :Locales, $knjpath + "locales.rb"
	autoload :Objects, $knjpath + "objects.rb"
	autoload :Opts, $knjpath + "opts.rb"
	autoload :Mail, $knjpath + "mail.rb"
	autoload :Mailobj, $knjpath + "mailobj.rb"
	autoload :Mount, $knjpath + "mount.rb"
	autoload :Mplayer, $knjpath + "mplayer.rb"
	autoload :Notify, $knjpath + "notify.rb"
	autoload :Nvidia_settings, $knjpath + "nvidia_settings.rb"
	autoload :Web, $knjpath + "web.rb"
	autoload :Google_sitemap, $knjpath + "google_sitemap.rb"
	autoload :Http, $knjpath + "http.rb"
	autoload :Sms, $knjpath + "sms.rb"
	autoload :Os, $knjpath + "os.rb"
	autoload :Gtk2, $knjpath + "gtk2.rb"
	autoload :Php, $knjpath + "php.rb"
	autoload :Php_parser, $knjpath + "php_parser/php_parser.rb"
	autoload :Power_manager, $knjpath + "power_manager.rb"
	autoload :Rand, $knjpath + "rand.rb"
	autoload :Retry, $knjpath + "retry.rb"
	autoload :RSVGBIN, $knjpath + "rsvgbin.rb"
	autoload :Strings, $knjpath + "strings.rb"
	autoload :SSHRobot, $knjpath + "sshrobot/sshrobot.rb"
	autoload :Sysuser, $knjpath + "sysuser.rb"
	autoload :Thread, $knjpath + "thread.rb"
	autoload :Thread2, $knjpath + "thread2.rb"
	autoload :Threadhandler, $knjpath + "threadhandler.rb"
	autoload :Translations, $knjpath + "translations.rb"
	autoload :X11VNC, $knjpath + "x11vnc.rb"
	autoload :Unix_proc, $knjpath + "unix_proc.rb"
	autoload :YouTube, $knjpath + "youtube.rb"
	autoload :Win, $knjpath + "win.rb"
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
autoload :Mysql, $knjpath + "autoload/mysql"
autoload :Open3, "open3"
autoload :OpenSSL, "openssl"
autoload :OptionParser, "optparse"
autoload :ParseDate, $knjpath + "autoload/backups/parsedate.rb"
autoload :Pathname, "pathname"
autoload :Ping, "ping"
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
autoload :WEBrick, "webrick"
autoload :XmlSimple, $knjpath + "autoload/xmlsimple"
autoload :Zip, $knjpath + "autoload/zip.rb"
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