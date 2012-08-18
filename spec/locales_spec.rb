require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Locales" do
  it "should do convertions of short formats" do
    Thread.current[:locale] = "en"
    res = Knj::Locales.lang
    raise "Result wasnt as expected: '#{res}'." if res["first"] != "en" or res["second"] != "GB" or res["full"] != "en_GB"
  end
end