# In case you want to use .sauce files from Capistrano directly
# Just put this in your Capfile or recipe
# require 'fake_sauce'
# load 'your.sauce' 
module Sauce
  def self.brew(appname, &block)
    abort("No fake sauce for you!  Use real sauce")
  end
end
