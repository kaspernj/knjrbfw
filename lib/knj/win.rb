module Knj::Win
  #Autoloader.
  def self.const_missing(name)
    require "#{$knjpath}knj/win_#{name.to_s.downcase}"
  end
end