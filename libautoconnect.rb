#knj's objects.
autoload :KnjGtkMenu, "knjrbfw/libknjgtk_menu"
autoload :KnjOS, "knjrbfw/libknjos"
autoload :KnjGtkMenu, "knjrbfw/libknjgtk_menu"

module Knj
	autoload :Db, "knjrbfw/knjdb/libknjdb"
	autoload :Db_row, "knjrbfw/knjdb/libknjdb_row"
	autoload :Objects, "knjrbfw/libobjects"
	autoload :Opts, "knjrbfw/libknjoptions"
	autoload :Gtk2, "knjrbfw/libknjgtk"
	autoload :Mail, "knjrbfw/mail.rb"
	autoload :Web, "knjrbfw/libknjweb"
	autoload :Strings, "knjrbfw/libstrings.rb"
	autoload :SSHRobot, "knjrbfw/sshrobot/sshrobot"
end

#ruby objects.
autoload :GetText, "gettext"
autoload :Gtk, "gtk2"
autoload :FileUtils, "fileutils"
autoload :Mysql, "mysql"

module Net
	autoload :IMAP, "net/imap"
	autoload :SMTP, "net/smtp"
	autoload :HTTP, "net/http"
end

module TMail
	autoload :Mail, "tmail"
end
