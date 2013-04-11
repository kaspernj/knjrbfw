#encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Db" do
  it "should be able to handle various encodings" do
    #I never got this test to actually fail... :-(
    
    require "knj/db"
    require "knj/os"
    require "rubygems"
    require "sqlite3" if !Kernel.const_defined?("SQLite3") and RUBY_ENGINE != "jruby"
    
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
    
    
    #Test revision to create tables, indexes and insert rows.
    schema = {
      "tables" => {
        "test_table" => {
          "columns" => [
            {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
            {"name" => "name", "type" => "varchar"},
            {"name" => "age", "type" => "int"},
            {"name" => "nickname", "type" => "varchar"}
          ],
          "indexes" => [
            "name"
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
    
    
    #Test wrong encoding.
    cont = File.read("#{File.dirname(__FILE__)}/db_spec_encoding_test_file.txt")
    cont.force_encoding("ASCII-8BIT")
    
    db.insert("test", {
      "text" => cont
    })
    
    
    #Throw out invalid encoding because it will make dumping fail.
    db.tables[:test].truncate
    
    
    
    #Test IDQueries.
    rows_count = 1250
    db.transaction do
      0.upto(rows_count) do |count|
        db.insert(:test_table, {:name => "User #{count}"})
      end
    end
    
    block_ran = 0
    idq = Knj::Db::Idquery.new(:db => db, :debug => false, :table => :test_table, :query => "SELECT id FROM test_table") do |data|
      block_ran += 1
    end
    
    raise "Block with should have ran too little: #{block_ran}." if block_ran < rows_count
    
    block_ran = 0
    db.select(:test_table, {}, {:idquery => true}) do |data|
      block_ran += 1
    end
    
    raise "Block with should have ran too little: #{block_ran}." if block_ran < rows_count
    
    
    #Test upserting.
    data = {:name => "Kasper Johansen"}
    sel = {:nickname => "kaspernj"}
    
    table = db.tables[:test_table]
    table.reload
    rows_count = table.rows_count
    
    db.upsert(:test_table, sel, data)
    
    table.reload
    table.rows_count.should eql(rows_count + 1)
    
    db.upsert(:test_table, sel, data)
    
    table.reload
    table.rows_count.should eql(rows_count + 1)
    
    
    #Test dumping.
    dump = Knj::Db::Dump.new(:db => db, :debug => false)
    str_io = StringIO.new
    dump.dump(str_io)
    str_io.rewind
    
    
    #Remember some numbers for validation.
    tables_count = db.tables.list.length
    
    
    #Remove everything in the db.
    db.tables.list do |table|
      table.drop unless table.native?
    end
    
    
    #Run the exported SQL.
    db.transaction do
      str_io.each_line do |sql|
        db.q(sql)
      end
    end
    
    
    #Vaildate import.
    raise "Not same amount of tables: #{tables_count}, #{db.tables.list.length}" if tables_count != db.tables.list.length
    
    
    
    #Test revision table renaming.
    Knj::Db::Revision.new.init_db("db" => db, "schema" => {
      "tables" => {
        "new_test_table" => {
          "renames" => ["test_table"]
        }
      }
    })
    tables = db.tables.list
    raise "Didnt expect table 'test_table' to exist but it did." if tables.key?("test_table")
    raise "Expected 'new_test_table' to exist but it didnt." if !tables.key?("new_test_table")
    
    
    #Test revision for column renaming.
    Knj::Db::Revision.new.init_db("db" => db, "schema" => {
      "tables" => {
        "new_test_table" => {
          "columns" => [
            {"name" => "new_name", "type" => "varchar", "renames" => ["name"]}
          ]
        }
      }
    })
    columns = db.tables["new_test_table"].columns
    raise "Didnt expect 'name' to exist but it did." if columns.key?("name")
    raise "Expected 'new_name'-column to exist but it didnt." if !columns.key?("new_name")
    
    
    #Delete test-database if everything went well.
    File.unlink(db_path) if File.exists?(db_path)
  end
  
  it "should generate proper sql" do
    require "knj/db"
    require "knj/os"
    require "rubygems"
    require "sqlite3" if !Kernel.const_defined?("SQLite3") and RUBY_ENGINE != "jruby"
    
    db_path = "#{Knj::Os.tmpdir}/knjrbfw_test_sqlite3.sqlite3"
    File.unlink(db_path) if File.exists?(db_path)
    
    db = Knj::Db.new(
      :type => "sqlite3",
      :path => db_path,
      :return_keys => "symbols",
      :index_append_table_name => true
    )
    
    time = Time.new(1985, 6, 17, 10, 30)
    db.insert(:test, {:date => time}, :return_sql => true).should eql("INSERT INTO `test` (`date`) VALUES ('1985-06-17 10:30:00')")
    
    date = Date.new(1985, 6, 17)
    db.insert(:test, {:date => date}, :return_sql => true).should eql("INSERT INTO `test` (`date`) VALUES ('1985-06-17')")
  end
end