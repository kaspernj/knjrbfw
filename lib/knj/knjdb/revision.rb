#This class takes a database-schema from a hash and runs it against the database. It then checks that the database matches the given schema.
#
#===Examples
# db = Knj::Db.new(:type => "sqlite3", :path => "test_db.sqlite3")
# schema = {
#   "tables" => {
#     "columns" => [
#       {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
#       {"name" => "name", "type" => "varchar"},
#       {"name" => "lastname", "type" => "varchar"}
#     ],
#     "indexes" => [
#       "name",
#       {"name" => "lastname", "columns" => ["lastname"]}
#     ]
#   }
# }
# 
# rev = Knj::Db::Revision.new
# rev.init_db("db" => db, "schema" => schema)
class Knj::Db::Revision
  def initialize(args = {})
    @args = args
  end
  
  #This initializes a database-structure and content based on a schema-hash.
  #===Examples
  # dbrev = Knj::Db::Revision.new
  # dbrev.init_db("db" => db_obj, "schema" => schema_hash)
  def init_db(args)
    schema = args["schema"]
    db = args["db"]
    
    #Check for normal bugs and raise apropiate error.
    raise "'schema' argument was not a Hash: '#{schema.class.name}'." if !schema.is_a?(Hash)
    raise "':return_keys' is not 'symbols' - Knjdbrevision will not work without it." if db.opts[:return_keys] != "symbols"
    raise "No tables given." if !schema.has_key?("tables")
    
    #Cache tables to avoid constant reloading.
    tables = db.tables.list
    
    schema["tables"].each do |table_name, table_data|
      begin
        begin
          raise Knj::Errors::NotFound if !tables.key?(table_name)
          table_obj = db.tables[table_name]
          
          #Cache indexes- and column-objects to avoid constant reloading.
          cols = table_obj.columns
          indexes = table_obj.indexes
          
          if table_data["columns"]
            first_col = true
            table_data["columns"].each do |col_data|
              begin
                col_obj = table_obj.column(col_data["name"])
                col_str = "#{table_name}.#{col_obj.name}"
                type = col_data["type"].to_s
                dochange = false
                
                if !first_col and !col_data["after"]
                  #Try to find out the previous column - if so we can set "after" which makes the column being created in the right order as defined.
                  if !col_data.has_key?("after")
                    prev_no = table_data["columns"].index(col_data)
                    if prev_no != nil and prev_no != 0
                      prev_no = prev_no - 1
                      prev_col_data = table_data["columns"][prev_no]
                      col_data["after"] = prev_col_data["name"]
                    end
                  end
                  
                  actual_after = nil
                  set_next = false
                  table_obj.columns do |col_iter|
                    if col_iter.name == col_obj.name
                      break
                    else
                      actual_after = col_iter.name
                    end
                  end
                  
                  if actual_after != col_data["after"]
                    print "Changing '#{col_str}' after from '#{actual_after}' to '#{col_data["after"]}'.\n" if args["debug"]
                    dochange = true
                  end
                end
                
                #BUGFIX: When using SQLite3 the primary-column or a autoincr-column may never change type from int... This will break it!
                if db.opts[:type] == "sqlite3" and col_obj.type.to_s == "int" and (col_data["primarykey"] or col_data["autoincr"]) and db.int_types.index(col_data["type"].to_s)
                  type = "int"
                end
                
                if type and col_obj.type.to_s != type
                  print "Type mismatch on #{col_str}: #{col_data["type"]}, #{col_obj.type}\n" if args["debug"]
                  dochange = true
                end
                
                if col_data.has_key?("maxlength") and col_obj.maxlength.to_s != col_data["maxlength"].to_s
                  print "Maxlength mismatch on #{col_str}: #{col_data["maxlength"]}, #{col_obj.maxlength}\n" if args["debug"]
                  dochange = true
                end
                
                if col_data.has_key?("null") and col_obj.null?.to_s != col_data["null"].to_s
                  print "Null mismatch on #{col_str}: #{col_data["null"]}, #{col_obj.null?}\n" if args["debug"]
                  dochange = true
                end
                
                if col_data.has_key?("default") and col_obj.default.to_s != col_data["default"].to_s
                  print "Default mismatch on #{col_str}: #{col_data["default"]}, #{col_obj.default}\n" if args["debug"]
                  dochange = true
                end
                
                if col_data.has_key?("comment") and col_obj.respond_to?(:comment) and col_obj.comment.to_s != col_data["comment"].to_s
                  print "Comment mismatch on #{col_str}: #{col_data["comment"]}, #{col_obj.comment}\n" if args["debug"]
                  dochange = true
                end
                
                if col_data.is_a?(Hash) and col_data["on_before_alter"]
                  callback_data = col_data["on_before_alter"].call("db" => db, "table" => table_obj, "col" => col_obj, "col_data" => col_data)
                  if callback_data and callback_data["action"]
                    if callback_data["action"] == "retry"
                      raise Knj::Errors::Retry
                    end
                  end
                end
                
                col_obj.change(col_data) if dochange
                first_col = false
              rescue Knj::Errors::NotFound => e
                print "Column not found: #{table_obj.name}.#{col_data["name"]}.\n" if args["debug"]
                
                if col_data.has_key?("renames")
                  raise "'renames' was not an array for column '#{table_obj.name}.#{col_data["name"]}'." if !col_data["renames"].is_a?(Array)
                  
                  rename_found = false
                  col_data["renames"].each do |col_name|
                    begin
                      col_rename = table_obj.column(col_name)
                    rescue Knj::Errors::NotFound => e
                      next
                    end
                    
                    print "Rename #{table_obj.name}.#{col_name} to #{table_obj.name}.#{col_data["name"]}\n" if args["debug"]
                    if col_data.is_a?(Hash) and col_data["on_before_rename"]
                      col_data["on_before_rename"].call("db" => db, "table" => table_obj, "col" => col_rename, "col_data" => col_data)
                    end
                    
                    col_rename.change(col_data)
                    
                    if col_data.is_a?(Hash) and col_data["on_after_rename"]
                      col_data["on_after_rename"].call("db" => db, "table" => table_obj, "col" => col_rename, "col_data" => col_data)
                    end
                    
                    rename_found = true
                    break
                  end
                  
                  retry if rename_found
                end
                
                oncreated = col_data["on_created"]
                col_data.delete("on_created") if col_data["oncreated"]
                col_obj = table_obj.create_columns([col_data])
                oncreated.call("db" => db, "table" => table_obj) if oncreated
              end
            end
          end
          
          if table_data["columns_remove"]
            table_data["columns_remove"].each do |column_name, column_data|
              begin
                col_obj = table_obj.column(column_name)
              rescue Knj::Errors::NotFound => e
                next
              end
              
              column_data["callback"].call if column_data.is_a?(Hash) and column_data["callback"]
              col_obj.drop
            end
          end
          
          if table_data["indexes"]
            table_data["indexes"].each do |index_data|
              if index_data.is_a?(String)
                index_data = {"name" => index_data, "columns" => [index_data]}
              end
              
              begin
                index_obj = table_obj.index(index_data["name"])
                
                rewrite_index = false
                rewrite_index = true if index_data.key?("unique") and index_data["unique"] != index_obj.unique?
                
                if rewrite_index
                  index_obj.drop
                  table_obj.create_indexes([index_data])
                end
              rescue Knj::Errors::NotFound => e
                table_obj.create_indexes([index_data])
              end
            end
          end
          
          if table_data["indexes_remove"]
            table_data["indexes_remove"].each do |index_name, index_data|
              begin
                index_obj = table_obj.index(index_name)
              rescue Knj::Errors::NotFound => e
                next
              end
              
              if index_data.is_a?(Hash) and index_data["callback"]
                index_data["callback"].call if index_data["callback"]
              end
              
              index_obj.drop
            end
          end
          
          self.rows_init("db" => db, "table" => table_obj, "rows" => table_data["rows"]) if table_data and table_data["rows"]
        rescue Knj::Errors::NotFound => e
          if table_data["renames"]
            table_data["renames"].each do |table_name_rename|
              begin
                raise Knj::Errors::NotFound if !tables.key?(table_name)
                table_rename = db.tables[table_name_rename]
                table_rename.rename(table_name)
                raise Knj::Errors::Retry
              rescue Knj::Errors::NotFound
                next
              end
            end
          end
          
          if !table_data.key?("columns")
            print "Notice: Skipping creation of '#{table_name}' because no columns were given in hash.\n"
            next
          end
          
          if table_data["on_create"]
            table_data["on_create"].call("db" => db, "table_name" => table_name, "table_data" => table_data)
          end
          
          db.tables.create(table_name, table_data)
          table_obj = db.tables[table_name]
          
          if table_data["on_create_after"]
            table_data["on_create_after"].call("db" => db, "table_name" => table_name, "table_data" => table_data)
          end
          
          self.rows_init("db" => db, "table" => table_obj, "rows" => table_data["rows"]) if table_data["rows"]
        end
      rescue Knj::Errors::Retry
        retry
      end
    end
    
    if schema["tables_remove"]
      schema["tables_remove"].each do |table_name, table_data|
        begin
          table_obj = db.tables[table_name.to_sym]
          table_data["callback"].call("db" => db, "table" => table_obj) if table_data.is_a?(Hash) and table_data["callback"]
          table_obj.drop
        rescue Knj::Errors::NotFound => e
          next
        end
      end
    end
    
    
    #Free cache.
    tables.clear
    tables = nil
  end
  
  private
  
  #This method checks if certain rows are present in a table based on a hash.
  def rows_init(args)
    db = args["db"]
    table = args["table"]
    
    raise "No db given." if !db
    raise "No table given." if !table
    
    args["rows"].each do |row_data|
      if row_data["find_by"]
        find_by = row_data["find_by"]
      elsif row_data["data"]
        find_by = row_data["data"]
      else
        raise "Could not figure out the find-by."
      end
      
      rows_found = 0
      args["db"].select(table.name, find_by) do |d_rows|
        rows_found += 1
        
        if Knj::ArrayExt.hash_diff?(Knj::ArrayExt.hash_sym(row_data["data"]), Knj::ArrayExt.hash_sym(d_rows), {"h2_to_h1" => false})
          print "Data was not right - updating row: #{JSON.generate(row_data["data"])}\n" if args["debug"]
          args["db"].update(table.name, row_data["data"], d_rows)
        end
      end
      
      if rows_found == 0
        print "Inserting row: #{JSON.generate(row_data["data"])}\n" if args["debug"]
        table.insert(row_data["data"])
      end
    end
  end
end