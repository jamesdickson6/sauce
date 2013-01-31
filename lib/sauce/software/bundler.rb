require 'sauce/software/gem'
module Sauce
  module Software
    # Bundler is a gem that handles dependency installation/management for other software.
    class Bundler < Software::Gem
      @software_name = "bundler"
      @software_command = "bundle"

      def check_directory(dir)
        run_command("cd #{dir} && #{try_sudo} #{command} check")
      end
            
      def install_directory(dir)
        run_command("cd #{dir} && #{try_sudo} #{command} install")
      end
            
    end
  end
end