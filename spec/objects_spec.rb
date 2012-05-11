require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Objects" do
  it "should be able to cache rows" do
    require "sqlite3"
    
    $db_path = "#{Knj::Os.tmpdir}/knjrbfw_objects_cache_test.sqlite3"
    $db = Knj::Db.new(:type => :sqlite3, :path => $db_path, :return_keys => "symbols")
    
    schema = {
      "tables" => {
        "User" => {
          "columns" => [
            {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
            {"name" => "username", "type" => "varchar"}
          ]
        }
      }
    }
    Knj::Db::Revision.new.init_db("schema" => schema, "db" => $db)
    
    class User < Knj::Datarow; end
    
    $ob = Knj::Objects.new(
      :db => $db,
      :datarow => true,
      :require => false,
      :models => {
        :User => {
          :cache_ids => true
        }
      }
    )
    
    $ob.adds(:User, [
      {:username => "User 1"},
      {:username => "User 2"},
      {:username => "User 3"},
      {:username => "User 4"},
      {:username => "User 5"}
    ])
    
    raise "Expected user-ID-cache to be 5 but it wasnt: #{$ob.ids_cache[:User].length}" if $ob.ids_cache[:User].length != 5
    
    user = $ob.get(:User, 4)
    $ob.delete(user)
    raise "Expected user-ID-cache to be 4 but it wasnt: #{$ob.ids_cache[:User].length} #{$ob.ids_cache}" if $ob.ids_cache[:User].length != 4
    
    $ob.deletes([$ob.get(:User, 1), $ob.get(:User, 2)])
    raise "Expected user-ID-cache to be 2 but it wasnt: #{$ob.ids_cache[:User].length} #{$ob.ids_cache}" if $ob.ids_cache[:User].length != 2
  end
  
  it "should delete the temporary database." do
    File.unlink($db_path) if File.exists?($db_path)
  end
end