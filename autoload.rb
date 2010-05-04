#knj's objects.
module Knj
	autoload :ArrayExt, "knj/arrayext"
	autoload :Db, "knj/knjdb/libknjdb"
	autoload :Db_row, "knj/knjdb/libknjdb_row"
	autoload :Objects, "knj/objects"
	autoload :Opts, "knj/opts"
	autoload :Mail, "knj/mail"
	autoload :Web, "knj/web"
	autoload :Strings, "knj/strings"
	autoload :SSHRobot, "knj/sshrobot/sshrobot"
	autoload :Datestamp, "knj/datestamp"
	autoload :Http, "knj/http"
	autoload :Sms, "knj/sms"
	autoload :Os, "knj/os"
	autoload :Gtk2, "knj/gtk2"
	autoload :Php, "knj/php"
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

#gems
autoload :Twitter, "knj/autoload/twitter"
autoload :Facebooker, "knj/autoload/facebooker"
autoload :Cinch, "knj/autoload/cinch"