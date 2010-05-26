$knjpath = File.dirname(__FILE__) + "/"

module Knj
	autoload :ArrayExt, $knjpath + "arrayext"
	autoload :Db, $knjpath + "knjdb/libknjdb"
	autoload :Db_row, $knjpath + "knjdb/libknjdb_row"
	autoload :Objects, $knjpath + "objects"
	autoload :Opts, $knjpath + "opts"
	autoload :Mail, $knjpath + "mail"
	autoload :Web, $knjpath + "web"
	autoload :Strings, $knjpath + "strings"
	autoload :SSHRobot, $knjpath + "sshrobot/sshrobot"
	autoload :Datestamp, $knjpath + "datestamp"
	autoload :Http, $knjpath + "http"
	autoload :Sms, $knjpath + "sms"
	autoload :Os, $knjpath + "os"
	autoload :Gtk2, $knjpath + "gtk2"
	autoload :Php, $knjpath + "php"
	autoload :Sysuser, $knjpath + "sysuser"
	autoload :Errors, $knjpath + "errors"
end

#ruby objects.
autoload :CGI, "cgi"
autoload :Date, "date"
autoload :Digest, "digest"
autoload :Erubis, "erubis"
autoload :FileUtils, "fileutils"
autoload :GetText, "gettext"
autoload :Gtk, "gtk2"
autoload :Mysql, "mysql"
autoload :ParseDate, "parsedate"
autoload :SQLite3, "sqlite3"
autoload :Ping, "ping"
autoload :SOAP, "knj/autoload/soap"

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