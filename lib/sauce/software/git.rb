require 'sauce/software/base'
require 'sauce/software/package_manager'
module Sauce
  module Software
    # Git SCM client
    class Git < Software::Base
      @software_name = "git"
      @software_command = "git"      

      # Maybe this should be a package manager too,
      # if it can be used to install things...?
      include PackageManager

    end
  end
end
