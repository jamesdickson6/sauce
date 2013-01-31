require 'sauce/software/base'
module Sauce
  module Software
    class Groovy < Software::Base
      @software_name = "groovy"
      
      depends_on "java"
      
    end
  end
end