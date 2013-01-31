require 'sauce/software/gem'
require 'sauce/software/service'
module Sauce
  module Software
    # Unicorn is an Application server for ruby/rails web applications
    class Unicorn < Software::Gem
      @software_name = "unicorn"
      @software_command = "unicorn"
      include Service
      
    end
  end
end
