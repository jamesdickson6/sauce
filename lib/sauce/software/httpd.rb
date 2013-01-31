require 'sauce/software/base'
require 'sauce/software/service'
module Sauce
  module Software
    # Httpd (Apache) is web server
    class Httpd < Software::Base
      @software_name = "httpd"
      @software_command = "httpd"      
      include Software::Service
    end
  end
end
