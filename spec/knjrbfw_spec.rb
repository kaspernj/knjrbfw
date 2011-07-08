require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Knjrbfw" do
  it "should be able to generate a sample SQLite database and add a sample table, with sample columns and with a sample index to it" do
    require "knjrbfw"
    require "knj/autoload"
    require "tmpdir"
    
    db_path = "/tmp/knjrbfw_test_sqlite3.sqlite3"
    
    begin
      db = Knj::Db.new(
        :type => "sqlite3",
        :path => db_path,
        :return_keys => "symbols",
        :index_append_table_name => true
      )
      
      db.tables.create("test_table", {
        "columns" => [
          {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
          {"name" => "category_id", "type" => "int"},
          {"name" => "name", "type" => "varchar"}
        ],
        "indexes" => [
          {"name" => "category_id", "columns" => ["category_id"]}
        ]
      })
      
      table = db.tables["test_table"]
      
      indexes = table.indexes
      raise "Could not find the sample-index 'category_id' that should have been created." if !indexes["category_id"]
      
      
      #If we insert a row the ID should increase and the name should be the same as inserted (or something is very very wrong)...
      db.insert("test_table", {
        "name" => "Kasper"
      })
      
      db.q("SELECT * FROM test_table") do |d|
        raise "Somehow name was not Kasper?" if d[:name] != "Kasper"
        raise "ID was not set?" if d[:id].to_i <= 0
      end
    ensure
      File.unlink(db_path) if File.exists?(db_path)
    end
  end
end
