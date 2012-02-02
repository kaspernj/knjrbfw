#encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Db" do
  it "should be able to handle various encodings" do
    #I never got this test to actually fail... :-(
    
    require "knj/db"
    require "tmpdir"
    require "sqlite3"
    
    db_path = "#{Dir.tmpdir}/knjrbfw_test_sqlite3.sqlite3"
    
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