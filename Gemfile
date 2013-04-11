source "http://rubygems.org"
# Add dependencies required to use your gem here.
# Example:
#   gem "activesupport", ">= 2.3.5"
gem "wref"
gem "tsafe"
gem "datet"
gem "http2"
gem "php4r"
gem "ruby_process"

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem "rspec"
  gem "bundler"
  gem "jeweler"
  gem "sqlite3" if RUBY_ENGINE != "jruby"
  gem "rmagick" if RUBY_ENGINE != "jruby"
  gem "rmagick4j" if RUBY_ENGINE == "jruby"
  gem "array_enumerator"
end
