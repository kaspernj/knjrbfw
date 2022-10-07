require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Knjrbfw" do
  it "should be able to join arrays with callbacks." do
    res = Knj::ArrayExt.join(:arr => [1, 2, 3], :sep => ",", :callback => proc{|value| "'#{value}'"})
    raise "Unexpected result from ArrayExt." if res != "'1','2','3'"
  end

  it "should be able to draw rounded transparent corners on images." do
    require "rubygems"
    require "rmagick"

    pic = Magick::Image.read("#{File.dirname(__FILE__)}/../testfiles/image.jpg").first
    pic.format = "png"

    Knj::Image.rounded_corners(
      :img => pic,
      :radius => 10
    )

    blob_cont = pic.to_blob
  end

  it "should be possible to use Strings.html_links-method." do
    teststr = "This is a test. http://www.google.com This is a test."

    #Test normal usage.
    test1 = Knj::Strings.html_links(teststr)
    raise "Unexpected string: '#{teststr}'" if test1 != "This is a test. <a href=\"http://www.google.com\">http://www.google.com</a> This is a test."


    #Test with a block.
    test2 = Knj::Strings.html_links(teststr) do |data|
      data[:str].gsub(data[:match][0], "TEST")
    end

    raise "Unexpected string: '#{test2}'." if test2 != "This is a test. TEST This is a test."
  end

=begin
  it "should be able to use Knj::Mutexcl with advanced arguments." do
    mutex = Knj::Mutexcl.new(
      :modes => {
        :reader => {
          :blocks => [:writer]
        },
        :writer => {
          :blocks => [:reader, :writer]
        }
      }
    )

    $count = 0

    Knj::Thread.new do
      mutex.sync(:reader) do
        sleep 0.2
        $count += 1
      end
    end

    mutex.sync(:reader) do
      $count += 1
    end

    raise "Count should be 1 by now but it wasnt: '#{$count}'." if $count != 1
    sleep 0.3
    raise "Count should be 2 by now but it wasnt: '#{$count}'." if $count != 2


    $count = 0
    Knj::Thread.new do
      mutex.sync(:reader) do
        sleep 2
        $count += 1
      end
    end
    sleep 0.1

    Knj::Thread.new do
      mutex.sync(:writer) do
        $count += 1
      end
    end

    sleep 1
    raise "Count should be 0 but it wasnt: '#{$count}'." if $count != 0
    sleep 1.1
    raise "Count should be 2 but it wasnt: '#{$count}'." if $count != 2

    Knj::Thread.new do
      mutex.sync(:reader) do
        sleep 0.2
        $count += 1
      end
    end

    Knj::Thread.new do
      mutex.sync(:reader) do
        sleep 0.2
        $count += 1
      end
    end

    sleep 0.35
    raise "Count should be 4 but it wasnt: '#{$count}'." if $count != 4
  end
=end
end
