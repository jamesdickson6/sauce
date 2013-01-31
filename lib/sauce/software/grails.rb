require 'sauce/software/base'
module Sauce
  module Software
    class Grails < Software::Base
      @software_name = "grails"

      depends_on "groovy"
      
    end
  end
end