$knjautoload = false

class Knj::Rhodes
  attr_reader :db, :ob, :gettext, :args
  
  def initialize(args = {})
    require "Knj/arrayext.rb"
    require "Knj/php.rb"
    require "Knj/objects.rb"
    require "Knj/datarow.rb"
    require "Knj/event_handler.rb"
    require "Knj/hash_methods.rb"
    require "Knj/errors.rb"
    require "Knj/gettext_threadded.rb"
    require "Knj/locales.rb"
    require "Knj/web.rb"
    require "Knj/rhodes/mutex.rb"
    require "Knj/opts.rb"
    
    require "Knj/knjdb/libknjdb.rb"
    require "Knj/knjdb/drivers/sqlite3/knjdb_sqlite3.rb"
    require "Knj/knjdb/drivers/sqlite3/knjdb_sqlite3_tables.rb"
    require "Knj/knjdb/drivers/sqlite3/knjdb_sqlite3_columns.rb"
    require "Knj/knjdb/drivers/sqlite3/knjdb_sqlite3_indexes.rb"
    
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
    
    require "knjdbrevision/knjdbrevision.rb"
    dbrev = Knjdbrevision.new
    dbrev.init_db(schema, @db)
    
    @ob = Knj::Objects.new(
      :db => @db,
      :class_path => "#{Rho::RhoApplication.get_base_app_path}app/Multinasser/include",
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
      
      data[:type] = :text if !data.has_key?(:type)
      
      if data.has_key?(:value) and data[:value].is_a?(Array) and data[:value][0]
        value = data[:value][0][data[:value][1]]
      elsif data.has_key?(:value)
        value = data[:value]
      end
      
      extra_args = ""
      extra_args = " autofocus=\"autofocus\"" if data[:autofocus]
      
      css = {}
      
      if data[:type] == :textarea
        css["height"] = data[:height] if data.has_key?(:height)
        
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
end