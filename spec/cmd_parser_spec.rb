require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Cmd_parser" do
  it "should be able to parse various strings" do
    require "knjrbfw"
    require "knj/cmd_parser"
    require "php4r"
    
    strs = [
      "-rw-r--r--    1 admin    administ   186.3M Aug 30 18:09 b4u_synoptik_2011_08_30_17_57_32.sql.gz\n",
      "-rw-r--r--    1 admin    administ        2 Nov 21 18:12 test\n",
      "-rw-r--r--  1 kaspernj kaspernj 279943393 2011-07-27 09:28 dbdump_2011_07_27_03_07_36.sql\n",
      "-rw-rw-r--  1 kaspernj kaspernj     58648 2011-10-28 18:33 2011-11-28 - Programmerings aften hos Anders - mad - 600 kr.pdf\n",
      "-rw-r--r-- 1 www-data www-data 4,0K 2011-05-16 23:21 dbbackup_2011_05_16-23:21:10.sql.gz\n"
    ]
    
    strs.each do |str|
      res = Knj::Cmd_parser.lsl(str)
      
      res.each do |file|
        raise "Byte was not numeric in: '#{str}'." if !(Float(file[:size]) rescue false)
      end
    end
  end
end