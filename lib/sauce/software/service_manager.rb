require 'sauce/software/base'
module Sauce
  module Software
    # Mix this into your class if it can start/stop/restart/reload other Software
    module ServiceManager

      module ClassMethods
        def translate_service_name(software_name)
          if defined?(self::SERVICE_NAME_MAP) 
            self::SERVICE_NAME_MAP[software_name] || software_name
          else
            software_name
          end
        end
      end

      def self.included(base)
        base.extend(ClassMethods)

        base.class_eval do

          ########################################################################
          # These base methods are overridden to operate on self or a software service
          # Necessary in case your service manager runs as a service itself
          ########################################################################
          
          alias :start_self :start
          def start(options={}, &block)
            (options[:software]||options[:service]) ? start_service(options, &block) : start_self(options, &block)
          end
          alias :stop_self :stop
          def stop(options={}, &block)
            (options[:software]||options[:service]) ? stop_service(options, &block) : stop_self(options, &block)
          end
          alias :restart_self :restart
          def restart(options={}, &block)
            (options[:software]||options[:service]) ? restart_service(options, &block) : restart_self(options, &block)
          end
          alias :reload_self :reload
          def reload(options={}, &block)
            (options[:software]||options[:service]) ? reload_service(options, &block) : reload_self(options, &block)
          end
          alias :status_self :status
          def status(options={}, &block)
            (options[:software]||options[:service]) ? status_service(options, &block) : status_self(options, &block)
          end
                              
          ########################################################################
          # Standard ServiceManager methods
          # These methods should conform to the run_command(options={},&block) interface
          # and return a CommandResult.  The easiest way to do this is just call #run_command(options) in your method.
          ########################################################################          
          
          def start_service(options={}, &block)
            service_name = parse_service_name(options)
            raise NotImplementedError.new("start_service() is not implemented by #{self.class.name}")
          end
          def stop_service(options={}, &block)
            service_name = parse_service_name(options)
            raise NotImplementedError.new("stop_service() is not implemented by #{self.class.name}")
          end
          def restart_service(options={}, &block)
            service_name = parse_service_name(options)
            raise NotImplementedError.new("restart_service() is not implemented by #{self.class.name}")
          end
          def reload_service(options={}, &block)
            service_name = parse_service_name(options)
            raise NotImplementedError.new("reload_service() is not implemented by #{self.class.name}")
          end
          def status_service(options={}, &block)
            service_name = parse_service_name(options)
            raise NotImplementedError.new("status_service() is not implemented by #{self.class.name}")
          end
                                                            
          protected
          
          # returns service name
          def parse_service_name(obj)
            software = obj.is_a?(Hash) ? (options[:software] || options[:service] : obj
            if software.is_a?(Software::Base)
              if software.respond_to?(:service_name) && software.service_name
                software = software.service_name
              else
                software = software.name
              end
            elsif software.is_a?(String) || software.is_a?(Symbol)
              software = software.to_s
            else
              raise ArgumentError.new("Expected a Software:Base, String or Symbol and instead got (#{software.class}) #{software}")
            end
            
            software = self.class.translate_service_name(software)
            return software
          end

        end
      end
      
    end
  end
end
