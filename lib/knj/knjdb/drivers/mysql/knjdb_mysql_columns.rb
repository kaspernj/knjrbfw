class KnjDB_mysql::Columns
  attr_reader :db, :driver
  
  def initialize(args)
    @args = args
    @db = @args[:db]
    @driver = @args[:driver]
  end
  
  def data_sql(data)
    raise "No type given." if !data["type"]
    
    data["maxlength"] = 255 if data["type"] == "varchar" and !data.key?("maxlength")
    
    sql = "`#{data["name"]}` #{data["type"]}"
    sql += "(#{data["maxlength"]})" if data["maxlength"]
    sql += " PRIMARY KEY" if data["primarykey"]
    sql += " AUTO_INCREMENT" if data["autoincr"]
    sql += " NOT NULL" if !data["null"]
    
    if data.key?("default_func")
      sql += " DEFAULT #{data["default_func"]}"
    elsif data.key?("default") and data["default"] != false
      sql += " DEFAULT '#{@db.escape(data["default"])}'"
    end
    
    sql += " COMMENT '#{@db.escape(data["comment"])}'" if data.key?("comment")
    sql += " AFTER `#{@db.esc_col(data["after"])}`" if data["after"] and !data["first"]
    sql += " FIRST" if data["first"]
    
    return sql
  end
end

class KnjDB_mysql::Columns::Column
  attr_reader :args
  
  def initialize(args)
    @args = args
    @db = @args[:db]
  end
  
  def name
    return @args[:data][:Field]
  end
  
  def data
    return {
      "type" => self.type,
      "name" => self.name,
      "null" => self.null?,
      "maxlength" => self.maxlength,
      "default" => self.default,
      "primarykey" => self.primarykey?,
      "autoincr" => self.autoincr?
    }
  end
  
  def type
    if !@type
      if match = @args[:data][:Type].match(/^([A-z]+)$/)
        @maxlength = false
        @type = match[0]
      elsif match = @args[:data][:Type].match(/^decimal\((\d+),(\d+)\)$/)
        @maxlength = "#{match[1]},#{match[2]}"
        @type = "decimal"
      elsif match = @args[:data][:Type].match(/^enum\((.+)\)$/)
        @maxlength = match[1]
        @type = "enum"
      elsif match = @args[:data][:Type].match(/^(.+)\((\d+)\)$/)
        @maxlength = match[2]
        @type = match[1]
      end
    end
    
    return @type
  end
  
  def null?
    return false if @args[:data][:Null] == "NO"
    return true
  end
  
  def maxlength
    self.type
    return @maxlength if @maxlength
    return false
  end
  
  def default
    return false if !@args[:data][:Default]
    return @args[:data][:Default]
  end
  
  def primarykey?
    return false if @args[:data][:pk].to_i == 0
    return true
  end
  
  def autoincr?
    return true if @args[:data][:Extra].index("auto_increment") != nil
    return false
  end
  
  def comment
    return @args[:data][:Comment]
  end
  
  def drop
    @args[:db].query("ALTER TABLE `#{@args[:table].name}` DROP COLUMN `#{self.name}`")
  end
  
  def change(data)
    esc_col = @args[:driver].escape_col
    col_escaped = "#{esc_col}#{@db.esc_col(self.name)}#{esc_col}"
    table_escape = "#{@args[:driver].escape_table}#{@args[:driver].esc_table(@args[:table].name)}#{@args[:driver].escape_table}"
    newdata = data.clone
    
    newdata["name"] = self.name if !newdata.key?("name")
    newdata["type"] = self.type if !newdata.key?("type")
    newdata["maxlength"] = self.maxlength if !newdata.key?("maxlength") and self.maxlength
    newdata["null"] = self.null? if !newdata.key?("null")
    newdata["default"] = self.default if !newdata.key?("default")
    newdata.delete("primarykey") if newdata.key?("primarykey")
    
    type_s = newdata["type"].to_s
    @db.query("ALTER TABLE #{table_escape} CHANGE #{col_escaped} #{@db.cols.data_sql(newdata)}")
    @args[:table].list = nil if data.key?("name") and data["name"] != self.name
  end
end