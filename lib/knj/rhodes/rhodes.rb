$knjautoload = false

class Knj::Rhodes
  attr_reader :db, :ob, :gettext, :args
  
  def initialize(args = {})
    require "#{$knjpath}arrayext.rb"
    require "#{$knjpath}php.rb"
    require "#{$knjpath}objects.rb"
    require "#{$knjpath}datarow.rb"
    require "#{$knjpath}event_handler.rb"
    require "#{$knjpath}hash_methods.rb"
    require "#{$knjpath}errors.rb"
    require "#{$knjpath}gettext_threadded.rb"
    require "#{$knjpath}locales.rb"
    require "#{$knjpath}web.rb"
    require "#{$knjpath}rhodes/mutex.rb"
    require "#{$knjpath}rhodes/weakref.rb"
    require "#{$knjpath}opts.rb"
    
    require "#{$knjpath}knjdb/libknjdb.rb"
    require "#{$knjpath}knjdb/revision.rb"
    require "#{$knjpath}knjdb/drivers/sqlite3/knjdb_sqlite3.rb"
    require "#{$knjpath}knjdb/drivers/sqlite3/knjdb_sqlite3_tables.rb"
    require "#{$knjpath}knjdb/drivers/sqlite3/knjdb_sqlite3_columns.rb"
    require "#{$knjpath}knjdb/drivers/sqlite3/knjdb_sqlite3_indexes.rb"
    
    @args = args
    
    @db = Knj::Db.new(
      :type => "sqlite3",
      :subtype => "rhodes",
      :path => "#{Rho::RhoApplication.get_base_app_path}app/rhodes_default.sqlite3",
      :return_keys => "symbols",
      :require => false
    )
    
    if @args[:schema]
      schema = @args[:schema]
    else
      schema = {"tables" => {}}
    end
    
    schema["tables"]["Option"] = {
      "columns" => [
        {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
        {"name" => "title", "type" => "varchar"},
        {"name" => "value", "type" => "text"}
      ]
    }
    
    dbrev = Knj::Db::Revision.new
    dbrev.init_db(schema, @db)
    
    @ob = Knj::Objects.new(
      :db => @db,
      :class_path => "#{Rho::RhoApplication.get_base_app_path}app/models",
      :require => false,
      :module => @args[:module],
      :datarow => true
    )
    
    Knj::Opts.init(
      "table" => "Option",
      "knjdb" => @db
    )
    
    @gettext = Knj::Gettext_threadded.new
    @gettext.load_dir("#{Rho::RhoApplication.get_base_app_path}app/locales")
  end
  
  def inputs(*arr)
    html = ""
    
    arr.each do |data|
      value = ""
      
      data[:type] = :text if !data.key?(:type)
      
      if data.key?(:value) and data[:value].is_a?(Array) and data[:value][0]
        value = data[:value][0][data[:value][1]]
      elsif data.key?(:value)
        value = data[:value]
      end
      
      extra_args = ""
      extra_args = " autofocus=\"autofocus\"" if data[:autofocus]
      
      css = {}
      
      if data[:type] == :textarea
        css["height"] = data[:height] if data.key?(:height)
        
        html += "<div data-role=\"fieldcontain\">"
        html += "<label for=\"#{data[:name]}\">#{data[:title]}</label>"
        html += "<textarea name=\"#{data[:name]}\" id=\"#{data[:name]}\"#{Knj::Web.style_html(css)}#{extra_args}>#{value}</textarea>"
        html += "</div>"
      else
        html += "<div data-role=\"fieldcontain\">"
        html += "<label for=\"#{data[:name]}\">#{data[:title]}</label>"
        html += "<input type=\"#{data[:type]}\" name=\"#{data[:name]}\" id=\"#{data[:name]}\" value=\"#{value}\"#{Knj::Web.style_html(css)}#{extra_args} />"
        html += "</div>"
      end
    end
    
    return html
  end
  
  def self.html_links(args)
    html_cont = "#{args[:html]}"
    
    html_cont.scan(/(<a([^>]+)href=\"(http.+?)\")/) do |match|
      html_cont = html_cont.gsub(match[0], "<a#{match[1]}href=\"javascript: knj_rhodes_html_links({url: '#{match[2]}'});\"")
    end
    
    return html_cont
  end
  
  def _(str)
    return @gettext.trans($locale, str.to_s)
  end
end