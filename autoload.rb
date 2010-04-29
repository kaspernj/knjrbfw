#knj's objects.
module Knj
	autoload :Db, "knj/knjdb/libknjdb"
	autoload :Db_row, "knj/knjdb/libknjdb_row"
	autoload :Objects, "knj/objects"
	autoload :Opts, "knj/opts"
	autoload :Mail, "knj/mail"
	autoload :Web, "knj/web"
	autoload :Strings, "knj/libstrings"
	autoload :SSHRobot, "knj/sshrobot/sshrobot"
	autoload :Date, "knj/date"
	autoload :Http, "knj/http"
	autoload :Sms, "knj/sms"
	autoload :Os, "knj/os"
	
	autoload :Gtk2, "knj/gtk2"
	module Gtk2
		autoload :Cb, "knj/gtk2_cb"
		autoload :Menu, "knj/gtk2_menu"
		autoload :StatusWindow, "knj/gtk2_statuswindow"
		autoload :Tv, "knj/gtk2_tv"
	end
end

#ruby objects.
autoload :GetText, "gettext"
autoload :Gtk, "gtk2"
autoload :FileUtils, "fileutils"
autoload :Mysql, "mysql"
autoload :ParseDate, "parsedate"
autoload :Digest, "digest/md5"

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