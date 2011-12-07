class Knj
  class Maemo
    class FremantleCalendar
      def initialize
        require "knjrbfw/libknjphpfuncs.rb"
        
        require "knjrbfw/knjdb/libknjdb.rb"
        @db = KnjDB.new({
          "type" => "sqlite3",
          "path" => "/home/user/.calendar/calendardb"
        })
      end
      
      def events
        ret = []
        f_gevents = @db.query("SELECT * FROM Components ORDER BY DateStart")
        while(d_gevents = f_gevents.fetch)
          ret << Event.new({
            "cal" => self,
            "data" => d_gevents,
            "db" => @db
          })
        end
        
        return ret
      end
      
      class Event
        def data; return @data; end
        def db; return @db; end
        def cal; return @cal; end
        
        def initialize(paras)
          @db = paras["db"]
          @data = paras["data"]
          @cal = paras["cal"]
        end
        
        def [](key)
          if (!@data.key?(key))
            raise "No such key: '" + key + "'"
          end
          
          return @data[key]
        end
        
        def []=(key, value)
          self[key] #raises error if key is invalid.
          
          @db.update("Components", {key => value}, {"Id" => @data["Id"]})
          @data[key] = value
        end
      end
    end
  end
end