#knj's objects.
module Knj
	autoload :Db, "knj/knjdb/libknjdb"
	autoload :Db_row, "knj/knjdb/libknjdb_row"
	autoload :Objects, "knj/objects"
	autoload :Opts, "knj/opts"
	autoload :Mail, "knj/mail"
	autoload :Web, "knj/web"
	autoload :Strings, "knj/strings"
	autoload :SSHRobot, "knj/sshrobot/sshrobot"
	autoload :Date, "knj/date"
	autoload :Http, "knj/http"
	autoload :Sms, "knj/sms"
	autoload :Os, "knj/os"
	autoload :Gtk2, "knj/gtk2"
	autoload :Php, "knj/php"
end

#ruby objects.
autoload :CGI, "cgi"
autoload :GetText, "gettext"
autoload :Gtk, "gtk2"
autoload :FileUtils, "fileutils"
autoload :Mysql, "mysql"
autoload :ParseDate, "parsedate"
autoload :Digest, "digest/md5"
autoload :SQLite3, "sqlite3"

module Net
	autoload :IMAP, "net/imap"
	autoload :SMTP, "net/smtp"
	autoload :HTTP, "net/http"
end

module TMail
	autoload :Mail, "tmail"
end

#facets
autoload :Dictionary, "facets/dictionary.rb"