require 'sauce/software/base'
module Sauce
  module Software
    class Java < Software::Base
      @software_name = "java"
      @software_command = "java"
      
      # never install java with a package manager
      def package_manager
        nil
      end
      
    end
  end
end