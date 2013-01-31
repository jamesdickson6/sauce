require 'sauce/software/base'
require 'sauce/software/rubygems'
module Sauce
  module Software
    # Base class for other Gems, which are installed via rubygems
    class Gem < Software::Base
      PACKAGE_MANAGER = Sauce::Software::Rubygems
      depends_on "rubygems"

      def package_manager
        Sauce::Software::Rubygems
      end

    end
  end
end
