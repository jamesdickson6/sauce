require 'sauce/software/base'
require 'sauce/software/service'
module Sauce
  module Software
    # Nginx is web server
    class Nginx < Software::Base
      @software_name = "nginx"
      @software_command = "nginx"
      include Software::Service

      def install_config(fn)
      end

      def uninstall_config(fn)
      end

    end
  end
end
