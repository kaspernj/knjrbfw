#encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Db" do
  it "should be able to handle various encodings" do
    #I never got this test to actually fail... :-(
    
    require "knj/db"
    require "knj/os"
    require "sqlite3" if !Kernel.const_defined?("SQLite3")
    
    db_path = "#{Knj::Os.tmpdir}/knjrbfw_test_sqlite3.sqlite3"
    File.unlink(db_path) if File.exists?(db_path)
    
    db = Knj::Db.new(
      :type => "sqlite3",
      :path => db_path,
      :return_keys => "symbols",
      :index_append_table_name => true
    )
    
    db.tables.create("test", {
      "columns" => [
        {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
        {"name" => "text", "type" => "varchar"}
      ]
    })
    
    
    
    #Get a list of tables and check the list for errors.
    list = db.tables.list
    raise "Table not found: 'test'." if !list.key?("test")
    raise "Table-name expected to be 'test' but wasnt: '#{list["test"].name}'." if list["test"].name != "test"
    
    
    #Test revision to create tables.
    schema = {
      "tables" => {
        "test_table" => {
          "columns" => [
            {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
            {"name" => "name", "type" => "varchar"}
          ],
          "rows" => [
            {
              "find_by" => {"id" => 1},
              "data" => {"id" => 1, "name" => "trala"}
            }
          ]
        }
      }
    }
    
    rev = Knj::Db::Revision.new
    rev.init_db("schema" => schema, "db" => db)
    
    begin
      cont = File.read("#{File.dirname(__FILE__)}/db_spec_encoding_test_file.txt")
      cont.force_encoding("ASCII-8BIT")
      
      db.insert("test", {
        "text" => cont
      })
    ensure
      File.unlink(db_path) if File.exists?(db_path)
    end
  end
end