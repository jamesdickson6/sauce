require 'sauce/software/base'
require 'sauce/software/package_manager'
module Sauce
  module Software
    # Package Manager for RPM-compatable Linux operating systems
    class Yum < Software::Base
      @software_name = "yum"
      @software_command = "yum"      
      
      PACKAGE_NAME_MAP = {
        "mysqld" => "mysql-server"
      }
      
      include PackageManager

      def install_package(options={})
        software, version = parse_software_args(software, version)
        logger.debug("Warning: #{self} cannot install specific versions right now!, installing the latest #{software}") if version
        #software_version = (software && version) ? "#{software}-#{version}" : software
        run_command("#{command} install -y #{software.name}")
      end

      def check_package(options={})
        software, version = parse_software_args((options[:software]||options[:package]), options[:version])
        cmd = "#{command} list installed #{software} | grep \"#{software}\" | awk '{print $2}' | grep \"^#{version}\""
        options[:shellescape] = false
        #options[:echo_out] = true
        run_command(cmd, options)
      end

      def uninstall_package(options={})
        software, version = parse_software_args((options[:software]||options[:package]), options[:version])
        cmd = "#{command} remove #{software}"
        options[:shellescape] = false
        run_command(cmd, options)
      end
            
    end
  end
end
