require 'sauce/software/base'
module Sauce
  module Software
    class Rails < Software::Base
      @software_name = "rails"
      @software_command = "rails"
      depends_on "rubygems"
      
      def package_manager
        @package_manager ||= Software::Rubygems
      end
      
    end
  end
end