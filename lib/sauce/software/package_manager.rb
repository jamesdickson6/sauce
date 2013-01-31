require 'sauce/software/base'
module Sauce
  module Software
    # Mix this into your class if it can install other Software
    module PackageManager
 
      module ClassMethods
        def translate_package_name(package_name)
          if defined?(self::PACKAGE_NAME_MAP) 
            self::PACKAGE_NAME_MAP[package_name] || package_name
          else
            package_name
          end
        end
      end

      def self.included(base)
        base.extend(ClassMethods)

        base.class_eval do

          ########################################################################
          # These base methods are overridden to operate on self or a software package
          # So for example, you can:
          #  homebrew.install # install homebrew
          #  homebrew.install :software => software # install nginx with homebrew
          ########################################################################
          
          alias :check_self :check
          def check(options={})
            (options[:software]||options[:package]) ? check_package(options) : check_self(options)
          end

          def installed?(options={})
            (options[:software]||options[:package]) ? check_package(options) : check_self(options)
          end

          alias :install_self :install
          def install(options={})
            (options[:software]||options[:package]) ? install_package(options) : install_self(options)
          end

          alias :uninstall_self :uninstall
          def uninstall(options={})
            (options[:software]||options[:package]) ? uninstall_package(options) : uninstall_self(options)
          end
          
          ########################################################################
          # Standard PackageManager methods
          # These methods should conform to the run_command(options={},&block) interface
          # and return a CommandResult.  The easiest way to do this is just call #run_command(options) in your method.
          ########################################################################          
          
          def check_package(options={})
            software, version = parse_software_args((options[:software]||options[:package]), options[:version])
            raise NotImplementedError.new("check_package() is not implemented by #{self.class.name}")
          end

          def install_package(options={})
            software, version = parse_software_args((options[:software]||options[:package]), options[:version])
            raise NotImplementedError.new("install_package() is not implemented by #{self.class.name}")
          end
          
          def uninstall_package(options={})
            software, version = parse_software_args((options[:software]||options[:package]), options[:version])
            raise NotImplementedError.new("run_uninstall_package() is not implemented by #{self.class.name}")
          end
          
          protected
          
          # returns software name, version
          def parse_software_args(software, version=nil)
            if software.is_a?(Software::Base)
              version ||= software.version
              software = software.name              
            elsif software.is_a?(String) || software.is_a?(Symbol)
              software = software.to_s
            else
              raise ArgumentError.new("Expected a Software:Base, String or Symbol and instead got (#{software.class}) #{software}")
            end
            
            software = self.class.translate_package_name(software)
            return software, version
          end

        end
      end
      
    end
  end
end
