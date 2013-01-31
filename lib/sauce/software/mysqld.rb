require 'sauce/software/base'
require 'sauce/software/service'
module Sauce
  module Software
    # MySQL Server
    class Mysqld < Software::Base
      @software_name = "mysqld"
      @software_command = "mysqld"
      include Service

      attr_accessor :basedir, :datadir

      # Don't use configuratation[:default_service_manager], it must be set explicitly.
      def service_manager
        @service_manager
      end

      def start_command
        cmd = "#{command}"
        cmd << " --basedir=#{basedir}" if basedir
        cmd << " --datadir=#{datadir}" if datadir
        cmd << " --defaults-file=#{config_file}" if config_file
        cmd << " --defaults-file=#{config_file}" if config_file        
        cmd
      end

      def run_start(options={})
        # options[:shellescape] = false
        run_command(start_cmd, options)
      end
      

    end
  end
end
