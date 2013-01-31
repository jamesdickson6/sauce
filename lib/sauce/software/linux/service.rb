require 'sauce/software/base'
require 'sauce/software/service_manager'
module Sauce
  module Software
    module Linux
      class Service < Software::Base
        @software_name = "service"
        @software_command = "service" # "/sbin/service"
        include ServiceManager

        def package_manager
          false
        end
        
        def start_service(options={}, &block)
          service_name = parse_service_name(options)
          run_command("#{command} #{service_name} start", options, &block)
        end
        def stop_service(options={}, &block)
          service_name = parse_service_name(options)
          run_command("#{command} #{service_name} stop", options, &block)
        end
        def restart_service(options={}, &block)
          service_name = parse_service_name(options)
          run_command("#{command} #{service_name} restart", options, &block)
        end
        def reload_service(options={}, &block)
          service_name = parse_service_name(options)
          run_command("#{command} #{service_name} reload", options, &block)
        end
        def status_service(options={}, &block)
          service_name = parse_service_name(options)      
          run_command("#{command} #{service_name} status", options, &block)
        end
      end
    end
  end
end