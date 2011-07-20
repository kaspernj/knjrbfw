require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Knjrbfw" do
  it "should be able to generate a sample SQLite database and add a sample table, with sample columns and with a sample index to it" do
    require "knjrbfw"
    require "knj/autoload"
    require "tmpdir"
    
    db_path = "#{Dir.tmpdir}/knjrbfw_test_sqlite3.sqlite3"
    
    begin
      db = Knj::Db.new(
        :type => "sqlite3",
        :path => db_path,
        :return_keys => "symbols",
        :index_append_table_name => true
      )
      
      db.tables.create("Project", {
        "columns" => [
          {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
          {"name" => "category_id", "type" => "int"},
          {"name" => "name", "type" => "varchar"}
        ],
        "indexes" => [
          {"name" => "category_id", "columns" => ["category_id"]}
        ]
      })
      
      db.tables.create("Task", {
        "columns" => [
          {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
          {"name" => "project_id", "type" => "int"},
          {"name" => "user_id", "type" => "int"},
          {"name" => "name", "type" => "varchar"}
        ],
        "indexes" => [
          {"name" => "project_id", "columns" => ["project_id"]}
        ]
      })
      
      db.tables.create("User", {
        "columns" => [
          {"name" => "id", "type" => "int", "autoincr" => true, "primarykey" => true},
          {"name" => "name", "type" => "varchar"}
        ]
      })
      
      table = db.tables["Project"]
      
      indexes = table.indexes
      raise "Could not find the sample-index 'category_id' that should have been created." if !indexes["category_id"]
      
      
      #If we insert a row the ID should increase and the name should be the same as inserted (or something is very very wrong)...
      db.insert("Project", {
        "name" => "Test project"
      })
      
      db.q("SELECT * FROM Project") do |d|
        raise "Somehow name was not 'Test project'" if d[:name] != "Test project"
        raise "ID was not set?" if d[:id].to_i <= 0
      end
      
      $db = db
    rescue => e
      File.unlink(db_path) if File.exists?(db_path)
      raise e
    end
  end
  
  it "should be able to parse various date formats." do
    date = Knj::Datet.in("2011-07-09 00:00:00 UTC")
    date = Knj::Datet.in("1985-06-17 01:00:00")
    date = Knj::Datet.in("1985-06-17")
    date = Knj::Datet.in("17/06 1985")
    
    raise "Couldnt register type 1 nullstamp." if !Knj::Datet.is_nullstamp?("0000-00-00")
    raise "Couldnt register type 2 nullstamp." if !Knj::Datet.is_nullstamp?("0000-00-00 00:00:00")
    raise "Registered nullstamp on valid date." if Knj::Datet.is_nullstamp?("1985-06-17")
    raise "Registered nullstamp on valid date." if Knj::Datet.is_nullstamp?("1985-06-17 10:30:00")
    
    date = Knj::Datet.in("2011-07-09 13:05:04 +0200")
    if date.time.localtime.to_s != "2011-07-09 15:05:04 +0200"
      raise "Datet didnt return expected result: '#{date.time.localtime}'."
    end
  end
  
  it "should be able to automatic generate methods on datarow-classes (has_many, has_one)." do
    class Project < Knj::Datarow
      has_many [
        {:classname => :Task, :colname => :project_id, :depends => true}
      ]
    end
    
    class Task < Knj::Datarow
      has_one [
        {:classname => :User, :required => true},
        :Project
      ]
      
      def self.list(d)
        sql = "SELECT * FROM Task WHERE 1=1"
        
        ret = list_helper(d)
        d.args.each do |key, val|
          raise sprintf("Invalid key: %s.", key)
        end
        
        sql += ret[:sql_where]
        sql += ret[:sql_order]
        sql += ret[:sql_limit]
        
        return d.ob.list_bysql(:Task, sql)
      end
    end
    
    class User < Knj::Datarow
      has_one [:Project]
      
      def html
        return self[:name]
      end
    end
    
    $ob = Knj::Objects.new(:db => $db, :datarow => true, :require => false)
    
    $ob.add(:User, {
      :name => "Kasper"
    })
    $ob.add(:Task, {
      :name => "Test task",
      :user_id => 1,
      :project_id => 1
    })
    
    project = $ob.get(:Project, 1)
    
    tasks = project.tasks
    raise "No tasks were found on project?" if tasks.empty?
    
    user = tasks[0].user
    project_second = tasks[0].project
    
    raise "Returned object was not a user on task." if !user.is_a?(User)
    raise "Returned object was not a project on task." if !project_second.is_a?(Project)
    
    
    #Check that has_many-depending is actually working.
    begin
      $ob.delete(project)
      raise "It was possible to delete project 1 even though task 1 depended on it!"
    rescue
      #this should happen - it should not possible to delete project 1 because task 1 depends on it."
    end
  end
  
  it "should be able to connect to objects 'no-html' callback and test it." do
    task = $ob.get(:Task, 1)
    $ob.events.connect(:no_html) do |event, classname|
      "[no #{classname.to_s.downcase}]"
    end
    
    raise "Unexpected user_html from task (should have been 'Kasper')." if task.user_html != "Kasper"
    task.update(:user_id => 0)
    raise "Unexpected user_html from task (should have been '[no user]')." if task.user_html != "[no user]"
  end
  
  it "should delete the temp database again." do
    db_path = "#{Dir.tmpdir}/knjrbfw_test_sqlite3.sqlite3"
    File.unlink(db_path) if File.exists?(db_path)
  end
  
  it "should be able to execute various Knj::Php functions correctly." do
    str = "Kasper Johansen"
    
    #substr
    teststr = Knj::Php.substr(str, 7, 8)
    if teststr != "Johansen"
      raise "substr did not return expected result: '#{teststr}'"
    end
    
    teststr = Knj::Php.substr(str, -8, 8)
    if teststr != "Johansen"
      raise "substr did not returned expected result when using negative positions: '#{teststr}'."
    end
    
    #strtoupper
    teststr = Knj::Php.strtoupper(str)
    if teststr != "KASPER JOHANSEN"
      raise "strtoupper did not return expected result: '#{teststr}'."
    end
    
    #strtolower
    teststr = Knj::Php.strtolower(str)
    if teststr != "kasper johansen"
      raise "strtolower did not return expected result: '#{teststr}'."
    end
  end
  
  it "should be able to join arrays with callbacks." do
    res = Knj::ArrayExt.join(:arr => [1, 2, 3], :sep => ",", :callback => proc{|value| "'#{value}'"})
    raise "Unexpected result from ArrayExt." if res != "'1','2','3'"
  end
  
  it "should be able to generate valid SQL based on arrays." do
    ret = $ob.sqlhelper({
      "test_col" => [1, 2, 3]
    },{
      :cols_str => ["test_col"]
    })
    
    raise "Unexpected SQL for generating based on array: '#{ret[:sql_where]}'" if ret[:sql_where] != " AND `test_col` IN ('1','2','3')"
  end
end
