require 'sauce/software/base'
module Sauce
  module Software
    # Mix this into your class if it depends on other Software
    # Dependencies are defined at the class level, and are inherited in subclasses
    # They can also be overriden in invidual Software instances.
    # Only one version of a particular 
    module SoftwareDependencies
      
      module ClassMethods
        
        # class level definition of software dependencies
        # Contains a hash of class => version, like {Software::Base => "1.0"}
        def software_dependencies
          @software_dependencies ||= {}
        end
        
        # class level helper for adding software dependency
        # This will replace an existing dependency of the same software class
        def add_software_dependency(software, version=nil)
          # get Software class based on flexible input
          case software
          when String, Symbol
            software = Software.find_class(software)
          when Class
            raise ArgumentError.new("Expected Software::Base and got #{software}") unless software < Software::Base
            software = software
          when Software::Base
            version ||= software.version
            software = software.class
          else 
            raise ArgumentError.new("#{software.inspect} can not be loaded as a software dependency. Expected a String,Symbol,Class or Software::Base instance")
          end
          # add/replaces version
          self.software_dependencies[software] = version
        end
        alias :depends_on :add_software_dependency

        # returns true/false as to whether this class depends on some software
        def depends_on?(software)
          case software.class
          when Class : self.software_dependencies.has_key?(software)
          when String, Symbol : self.software_dependencies.keys.find {|i| i.name == software.to_s }
          else false
          end
        end
        
      end # ClassMethods

      def self.included(base)
        base.extend(ClassMethods)

        base.class_eval do
          # inherit class level dependencies
          if superclass.respond_to?(:software_dependencies)
            @software_dependencies = superclass.software_dependencies.clone
          else
            @software_dependencies = {}
          end

          # caches and returns Array of Software instances based on class value
          def software_dependencies
            return @software_dependencies if @software_dependencies
            @software_dependencies = []
            self.class.software_dependencies.each do |klass, version|
              @software_dependencies << klass.new(self.configuration, {:version=>version})
            end
            @software_dependencies
          end

          # checks name only, not version
          def depends_on?(software)
            case software
            when Class then self.software_dependencies.find {|i| i.class == software}
            when String, Symbol then self.software_dependencies.keys.find {|i| i.name == software.to_s }
            else false
            end
          end

          # returns true/false
          def software_dependencies_installed?(options={}, &block)
            return software_dependencies.all? {|s| s.installed?(options, &block) }
          end
          
          # returns array of dependencies that are NOT installed
          def missing_software_dependencies(options={}, &block)
            return software_dependencies.select {|s| !s.installed?(options, &block) }
          end
          # returns true/value
          def missing_software_dependencies?(options={}, &block)
            return missing_software_dependencies(options={}, &block).empty?
          end          

          def install_software_dependencies(options, &block)
            return software_dependencies.all? {|s| s.install(options, &block) }
          end

        end # instance_eval

      end # included

    end
  end
end
