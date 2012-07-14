source "http://rubygems.org"
# Add dependencies required to use your gem here.
# Example:
#   gem "activesupport", ">= 2.3.5"
gem "wref"
gem "tsafe"
gem "datet"
gem "http2"

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem "rspec", "~> 2.3.0"
  gem "bundler", ">= 1.0.0"
  gem "jeweler", "~> 1.6.3"
  gem "rcov", ">= 0"
  gem "sqlite3" if RUBY_ENGINE != "jruby"
  gem "rmagick" if RUBY_ENGINE != "jruby"
  gem "rmagick4j" if RUBY_ENGINE == "jruby"
end
