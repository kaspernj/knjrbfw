# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{knjrbfw}
  s.version = "0.0.34"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Kasper Johansen"]
  s.date = %q{2012-05-19}
  s.description = %q{Including stuff for HTTP, SSH and much more.}
  s.email = %q{k@spernj.org}
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".rspec",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "knjrbfw.gemspec",
    "lib/knj/.gitignore",
    "lib/knj/amixer.rb",
    "lib/knj/arrayext.rb",
    "lib/knj/autoload.rb",
    "lib/knj/autoload/activesupport.rb",
    "lib/knj/autoload/backups/facets_dictionary.rb",
    "lib/knj/autoload/backups/parsedate.rb",
    "lib/knj/autoload/backups/ping.rb",
    "lib/knj/autoload/cinch.rb",
    "lib/knj/autoload/erubis.rb",
    "lib/knj/autoload/facebooker.rb",
    "lib/knj/autoload/facets_dictionary.rb",
    "lib/knj/autoload/gd2.rb",
    "lib/knj/autoload/gettext.rb",
    "lib/knj/autoload/gtk2.rb",
    "lib/knj/autoload/json.rb",
    "lib/knj/autoload/magick.rb",
    "lib/knj/autoload/mysql.rb",
    "lib/knj/autoload/parsedate.rb",
    "lib/knj/autoload/ping.rb",
    "lib/knj/autoload/rexml.rb",
    "lib/knj/autoload/soap.rb",
    "lib/knj/autoload/sqlite3.rb",
    "lib/knj/autoload/tmail.rb",
    "lib/knj/autoload/tzinfo.rb",
    "lib/knj/autoload/wref.rb",
    "lib/knj/autoload/xmlsimple.rb",
    "lib/knj/autoload/zip.rb",
    "lib/knj/cmd_gen.rb",
    "lib/knj/cmd_parser.rb",
    "lib/knj/compiler.rb",
    "lib/knj/cpufreq.rb",
    "lib/knj/csv.rb",
    "lib/knj/datarow.rb",
    "lib/knj/datarow_custom.rb",
    "lib/knj/datestamp.rb",
    "lib/knj/datet.rb",
    "lib/knj/db.rb",
    "lib/knj/degulesider.rb",
    "lib/knj/erb/apache_knjerb.conf",
    "lib/knj/erb/cache/README",
    "lib/knj/erb/erb.rb",
    "lib/knj/erb/erb_1.9.rb",
    "lib/knj/erb/erb_cache_clean.rb",
    "lib/knj/erb/erb_fcgi.rb",
    "lib/knj/erb/erb_fcgi_1.9.rb",
    "lib/knj/erb/erb_fcgi_jruby.rb",
    "lib/knj/erb/erb_jruby.rb",
    "lib/knj/erb/include.rb",
    "lib/knj/errors.rb",
    "lib/knj/eruby.rb",
    "lib/knj/event_filemod.rb",
    "lib/knj/event_handler.rb",
    "lib/knj/exchangerates.rb",
    "lib/knj/facebook_connect.rb",
    "lib/knj/filesystem.rb",
    "lib/knj/fs/drivers/filesystem.rb",
    "lib/knj/fs/drivers/ftp.rb",
    "lib/knj/fs/drivers/ssh.rb",
    "lib/knj/fs/fs.rb",
    "lib/knj/gettext_fallback.rb",
    "lib/knj/gettext_threadded.rb",
    "lib/knj/google_sitemap.rb",
    "lib/knj/gtk2.rb",
    "lib/knj/gtk2_cb.rb",
    "lib/knj/gtk2_menu.rb",
    "lib/knj/gtk2_statuswindow.rb",
    "lib/knj/gtk2_tv.rb",
    "lib/knj/hash_methods.rb",
    "lib/knj/http.rb",
    "lib/knj/http2.rb",
    "lib/knj/image.rb",
    "lib/knj/includes/appserver_cli.rb",
    "lib/knj/includes/require_info.rb",
    "lib/knj/ip2location.rb",
    "lib/knj/ironruby-gtk2/button.rb",
    "lib/knj/ironruby-gtk2/dialog.rb",
    "lib/knj/ironruby-gtk2/entry.rb",
    "lib/knj/ironruby-gtk2/gdk_event.rb",
    "lib/knj/ironruby-gtk2/gdk_eventbutton.rb",
    "lib/knj/ironruby-gtk2/gdk_pixbuf.rb",
    "lib/knj/ironruby-gtk2/gladexml.rb",
    "lib/knj/ironruby-gtk2/glib.rb",
    "lib/knj/ironruby-gtk2/gtk2.rb",
    "lib/knj/ironruby-gtk2/gtk_builder.rb",
    "lib/knj/ironruby-gtk2/gtk_cellrenderertext.rb",
    "lib/knj/ironruby-gtk2/gtk_combobox.rb",
    "lib/knj/ironruby-gtk2/gtk_filechooserbutton.rb",
    "lib/knj/ironruby-gtk2/gtk_liststore.rb",
    "lib/knj/ironruby-gtk2/gtk_menu.rb",
    "lib/knj/ironruby-gtk2/gtk_menuitem.rb",
    "lib/knj/ironruby-gtk2/gtk_statusicon.rb",
    "lib/knj/ironruby-gtk2/gtk_treeiter.rb",
    "lib/knj/ironruby-gtk2/gtk_treeselection.rb",
    "lib/knj/ironruby-gtk2/gtk_treeview.rb",
    "lib/knj/ironruby-gtk2/gtk_treeviewcolumn.rb",
    "lib/knj/ironruby-gtk2/iconsize.rb",
    "lib/knj/ironruby-gtk2/image.rb",
    "lib/knj/ironruby-gtk2/label.rb",
    "lib/knj/ironruby-gtk2/stock.rb",
    "lib/knj/ironruby-gtk2/tests/test.glade",
    "lib/knj/ironruby-gtk2/tests/test_2.rb",
    "lib/knj/ironruby-gtk2/tests/test_ironruby_window.rb",
    "lib/knj/ironruby-gtk2/vbox.rb",
    "lib/knj/ironruby-gtk2/window.rb",
    "lib/knj/jruby-gtk2/builder.rb",
    "lib/knj/jruby-gtk2/builder/test_builder.glade",
    "lib/knj/jruby-gtk2/builder/test_builder.rb",
    "lib/knj/jruby-gtk2/builder/test_builder.ui",
    "lib/knj/jruby-gtk2/cellrenderertext.rb",
    "lib/knj/jruby-gtk2/checkbutton.rb",
    "lib/knj/jruby-gtk2/combobox.rb",
    "lib/knj/jruby-gtk2/dialog.rb",
    "lib/knj/jruby-gtk2/eventbutton.rb",
    "lib/knj/jruby-gtk2/gladexml.rb",
    "lib/knj/jruby-gtk2/gtk2.rb",
    "lib/knj/jruby-gtk2/hbox.rb",
    "lib/knj/jruby-gtk2/iconsize.rb",
    "lib/knj/jruby-gtk2/image.rb",
    "lib/knj/jruby-gtk2/liststore.rb",
    "lib/knj/jruby-gtk2/menu.rb",
    "lib/knj/jruby-gtk2/progressbar.rb",
    "lib/knj/jruby-gtk2/statusicon.rb",
    "lib/knj/jruby-gtk2/stock.rb",
    "lib/knj/jruby-gtk2/tests/test_glade_window.glade",
    "lib/knj/jruby-gtk2/tests/test_glade_window.rb",
    "lib/knj/jruby-gtk2/tests/test_normal_window.rb",
    "lib/knj/jruby-gtk2/tests/test_trayicon.png",
    "lib/knj/jruby-gtk2/tests/test_trayicon.rb",
    "lib/knj/jruby-gtk2/treeview.rb",
    "lib/knj/jruby-gtk2/vbox.rb",
    "lib/knj/jruby-gtk2/window.rb",
    "lib/knj/jruby/sqlitejdbc-v056.jar",
    "lib/knj/jruby_compiler.rb",
    "lib/knj/knj.rb",
    "lib/knj/knj_controller.rb",
    "lib/knj/knjdb/dbtime.rb",
    "lib/knj/knjdb/drivers/mysql/knjdb_mysql.rb",
    "lib/knj/knjdb/drivers/mysql/knjdb_mysql_columns.rb",
    "lib/knj/knjdb/drivers/mysql/knjdb_mysql_indexes.rb",
    "lib/knj/knjdb/drivers/mysql/knjdb_mysql_tables.rb",
    "lib/knj/knjdb/drivers/sqlite3/knjdb_sqlite3.rb",
    "lib/knj/knjdb/drivers/sqlite3/knjdb_sqlite3_columns.rb",
    "lib/knj/knjdb/drivers/sqlite3/knjdb_sqlite3_indexes.rb",
    "lib/knj/knjdb/drivers/sqlite3/knjdb_sqlite3_tables.rb",
    "lib/knj/knjdb/libknjdb.rb",
    "lib/knj/knjdb/libknjdb_java_sqlite3.rb",
    "lib/knj/knjdb/libknjdb_row.rb",
    "lib/knj/knjdb/libknjdb_sqlite3_ironruby.rb",
    "lib/knj/knjdb/revision.rb",
    "lib/knj/kvm.rb",
    "lib/knj/libqt.rb",
    "lib/knj/libqt_window.rb",
    "lib/knj/locale_strings.rb",
    "lib/knj/locales.rb",
    "lib/knj/maemo/fremantle-calendar/fremantle-calendar.rb",
    "lib/knj/mail.rb",
    "lib/knj/mailobj.rb",
    "lib/knj/memory_analyzer.rb",
    "lib/knj/mount.rb",
    "lib/knj/mutexcl.rb",
    "lib/knj/notify.rb",
    "lib/knj/nvidia_settings.rb",
    "lib/knj/objects.rb",
    "lib/knj/objects/objects_sqlhelper.rb",
    "lib/knj/opts.rb",
    "lib/knj/os.rb",
    "lib/knj/php.rb",
    "lib/knj/php_parser/arguments.rb",
    "lib/knj/php_parser/functions.rb",
    "lib/knj/php_parser/php_parser.rb",
    "lib/knj/php_parser/tests/test.rb",
    "lib/knj/php_parser/tests/test_function.php",
    "lib/knj/php_parser/tests/test_function_run.rb",
    "lib/knj/power_manager.rb",
    "lib/knj/process.rb",
    "lib/knj/process_meta.rb",
    "lib/knj/rand.rb",
    "lib/knj/retry.rb",
    "lib/knj/rhodes/mutex.rb",
    "lib/knj/rhodes/rhodes.js",
    "lib/knj/rhodes/rhodes.rb",
    "lib/knj/rhodes/youtube_embed.erb",
    "lib/knj/rhodes/youtube_open.erb",
    "lib/knj/rsvgbin.rb",
    "lib/knj/scripts/degulesider.rb",
    "lib/knj/scripts/filesearch.rb",
    "lib/knj/scripts/ip2location.rb",
    "lib/knj/scripts/keepalive.rb",
    "lib/knj/scripts/php_to_rb_helper.rb",
    "lib/knj/scripts/process_meta_exec.rb",
    "lib/knj/scripts/svn_merge.rb",
    "lib/knj/scripts/upgrade_knjrbfw_checker.rb",
    "lib/knj/sms.rb",
    "lib/knj/sshrobot.rb",
    "lib/knj/sshrobot/sshrobot.rb",
    "lib/knj/strings.rb",
    "lib/knj/sysuser.rb",
    "lib/knj/table_writer.rb",
    "lib/knj/tests/compiler/compiler_test.rb",
    "lib/knj/tests/compiler/compiler_test_file.rb",
    "lib/knj/tests/test_degulesider.rb",
    "lib/knj/tests/test_http2.rb",
    "lib/knj/tests/test_http2_proxy.rb",
    "lib/knj/tests/test_mount.rb",
    "lib/knj/tests/test_retry.rb",
    "lib/knj/thread.rb",
    "lib/knj/thread2.rb",
    "lib/knj/threadhandler.rb",
    "lib/knj/threadpool.rb",
    "lib/knj/threadsafe.rb",
    "lib/knj/translations.rb",
    "lib/knj/unix_proc.rb",
    "lib/knj/web.rb",
    "lib/knj/webscripts/image.rhtml",
    "lib/knj/win.rb",
    "lib/knj/win_registry.rb",
    "lib/knj/win_tightvnc.rb",
    "lib/knj/x11vnc.rb",
    "lib/knj/youtube.rb",
    "lib/knjrbfw.rb",
    "spec/amixer_spec.rb",
    "spec/cmd_parser_spec.rb",
    "spec/datet_spec.rb",
    "spec/db_spec.rb",
    "spec/db_spec_encoding_test_file.txt",
    "spec/http2_spec.rb",
    "spec/knjrbfw_spec.rb",
    "spec/objects_spec.rb",
    "spec/php_spec.rb",
    "spec/process_meta_spec.rb",
    "spec/process_spec.rb",
    "spec/spec_helper.rb",
    "spec/strings_spec.rb",
    "spec/threadsafe_spec.rb",
    "spec/web_spec.rb",
    "testfiles/image.jpg"
  ]
  s.homepage = %q{http://github.com/kaspernj/knjrbfw}
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{A framework with lots of stuff for Ruby.}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<wref>, [">= 0"])
      s.add_runtime_dependency(%q<tsafe>, [">= 0"])
      s.add_development_dependency(%q<rspec>, ["~> 2.3.0"])
      s.add_development_dependency(%q<bundler>, [">= 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.3"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
      s.add_development_dependency(%q<sqlite3>, [">= 0"])
      s.add_development_dependency(%q<rmagick>, [">= 0"])
    else
      s.add_dependency(%q<wref>, [">= 0"])
      s.add_dependency(%q<tsafe>, [">= 0"])
      s.add_dependency(%q<rspec>, ["~> 2.3.0"])
      s.add_dependency(%q<bundler>, [">= 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.3"])
      s.add_dependency(%q<rcov>, [">= 0"])
      s.add_dependency(%q<sqlite3>, [">= 0"])
      s.add_dependency(%q<rmagick>, [">= 0"])
    end
  else
    s.add_dependency(%q<wref>, [">= 0"])
    s.add_dependency(%q<tsafe>, [">= 0"])
    s.add_dependency(%q<rspec>, ["~> 2.3.0"])
    s.add_dependency(%q<bundler>, [">= 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.3"])
    s.add_dependency(%q<rcov>, [">= 0"])
    s.add_dependency(%q<sqlite3>, [">= 0"])
    s.add_dependency(%q<rmagick>, [">= 0"])
  end
end

