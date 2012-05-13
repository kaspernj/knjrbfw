require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Objects" do
  it "should be able to cache rows" do
    require "sqlite3" if RUBY_ENGINE != "jruby"
    
    $db_path = "#{Knj::Os.tmpdir}/knjrbfw_objects_cache_test.sqlite3"
    File.unlink($db_path) if File.exists?($db_path)
    $db = Knj::Db.new(:type => :sqlite3, :path => $db_path, :return_keys => "symbols")
    
    schema = {
      "tables" => {
        "Group" => {
          "columns" => [
            {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
            {"name" => "groupname", "type" => "varchar"}
          ]
        },
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
  
  it "should work even though stressed by threads (thread-safe)." do
    userd = []
    10.upto(25) do |i|
      userd << {:username => "User #{i}"}
    end
    
    $ob.adds(:User, userd)
    users = $ob.list(:User)
    
    #Stress it to test threadsafety...
    threads = []
    0.upto(10) do |tc|
      threads << Knj::Thread.new do
        0.upto(10) do |ic|
          user = $ob.add(:User, {:username => "User #{tc}-#{ic}"})
          $ob.delete(user)
          
          user1 = $ob.add(:User, {:username => "User #{tc}-#{ic}-1"})
          user2 = $ob.add(:User, {:username => "User #{tc}-#{ic}-2"})
          user3 = $ob.add(:User, {:username => "User #{tc}-#{ic}-3"})
          $ob.deletes([user1, user2, user3])
          
          users.each do |user|
            user[:username] = "#{user[:username]}." if !user.deleted?
          end
        end
      end
    end
    
    threads.each do |thread|
      thread.join
    end
  end
  
  it "should be able to skip queries when adding" do
    class Group < Knj::Datarow; end
    
    $ob2 = Knj::Objects.new(
      :db => $db,
      :datarow => true,
      :require => false
    )
    
    threads = []
    0.upto(10) do
      threads << Knj::Thread.new do
        0.upto(15) do
          $ob2.add(:Group, {:groupname => "User 1"}, {:skip_ret => true})
        end
      end
    end
    
    threads.each do |thread|
      thread.join
    end
  end
  
  it "should delete the temporary database." do
    File.unlink($db_path) if File.exists?($db_path)
  end
  
  #Moved from "knjrbfw_spec.rb"
  it "should be able to generate a sample SQLite database and add a sample table, with sample columns and with a sample index to it" do
    $db_path = "#{Knj::Os.tmpdir}/knjrbfw_test_sqlite3.sqlite3"
    $db = Knj::Db.new(
      :type => "sqlite3",
      :path => $db_path,
      :return_keys => "symbols",
      :index_append_table_name => true
    )
    
    $db.tables.create("Project", {
      "columns" => [
        {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
        {"name" => "category_id", "type" => "int"},
        {"name" => "name", "type" => "varchar"}
      ],
      "indexes" => [
        {"name" => "category_id", "columns" => ["category_id"]}
      ]
    })
    
    $db.tables.create("Task", {
      "columns" => [
        {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
        {"name" => "project_id", "type" => "int"},
        {"name" => "person_id", "type" => "int"},
        {"name" => "name", "type" => "varchar"}
      ],
      "indexes" => [
        {"name" => "project_id", "columns" => ["project_id"]}
      ]
    })
    
    $db.tables.create("Person", {
      "columns" => [
        {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
        {"name" => "name", "type" => "varchar"}
      ]
    })
    
    table = $db.tables["Project"]
    
    indexes = table.indexes
    raise "Could not find the sample-index 'category_id' that should have been created." if !indexes["Project__category_id"]
    
    
    #If we insert a row the ID should increase and the name should be the same as inserted (or something is very very wrong)...
    $db.insert("Project", {
      "name" => "Test project"
    })
    
    $db.q("SELECT * FROM Project") do |d|
      raise "Somehow name was not 'Test project'" if d[:name] != "Test project"
      raise "ID was not set?" if d[:id].to_i <= 0
    end
  end
  
  it "should be able to automatic generate methods on datarow-classes (has_many, has_one)." do
    class Project < Knj::Datarow
      has_many [
        {:class => :Task, :col => :project_id, :depends => true}
      ]
    end
    
    class Task < Knj::Datarow
      has_one [
        {:class => :Person, :required => true},
        :Project
      ]
    end
    
    class Person < Knj::Datarow
      has_one [:Project]
      
      def html
        return self[:name]
      end
    end
    
    $ob = Knj::Objects.new(:db => $db, :datarow => true, :require => false)
    
    $ob.add(:Person, {
      :name => "Kasper"
    })
    $ob.add(:Task, {
      :name => "Test task",
      :person_id => 1,
      :project_id => 1
    })
    
    ret_proc = []
    $ob.list(:Task) do |task|
      ret_proc << task
    end
    
    raise "list with proc should return one task but didnt." if ret_proc.length != 1
    
    
    project = $ob.get(:Project, 1)
    
    tasks = project.tasks
    raise "No tasks were found on project?" if tasks.empty?
    
    
    ret_proc = []
    ret_test = project.tasks do |task|
      ret_proc << task
    end
    
    raise "When given a block the return should be nil so it doesnt hold weak-ref-objects in memory but it didnt return nil." if ret_test != nil
    raise "list for project with proc should return one task but didnt (#{ret_proc.length})." if ret_proc.length != 1
    
    person = tasks.first.person
    project_second = tasks.first.project
    
    raise "Returned object was not a person on task." if !person.is_a?(Person)
    raise "Returned object was not a project on task." if !project_second.is_a?(Project)
    
    
    #Check that has_many-depending is actually working.
    begin
      $ob.delete(project)
      raise "It was possible to delete project 1 even though task 1 depended on it!"
    rescue
      #this should happen - it should not possible to delete project 1 because task 1 depends on it."
    end
  end
  
  it "should be able to generate lists for inputs" do
    Knj::Web.inputs([{
      :title => "Test 3",
      :name => :seltest3,
      :type => :select,
      :default => 1,
      :opts => $ob.list_optshash(:Task)
    }])
  end
  
  it "should be able to connect to objects 'no-html' callback and test it." do
    task = $ob.get(:Task, 1)
    $ob.events.connect(:no_html) do |event, classname|
      "[no #{classname.to_s.downcase}]"
    end
    
    raise "Unexpected person_html from task (should have been 'Kasper'): '#{task.person_html}'." if task.person_html != "Kasper"
    task.update(:person_id => 0)
    raise "Unexpected person_html from task (should have been '[no person]')." if task.person_html != "[no person]"
  end
  
  it "should delete the temp database again." do
    db_path = "#{Knj::Os.tmpdir}/knjrbfw_test_sqlite3.sqlite3"
    File.unlink(db_path) if File.exists?(db_path)
  end
end