require 'sauce'
require 'sauce/cookable'
module Sauce
  # cookable application and its environments
  class Application
    include Cookable
    attr_reader :name, :environments

    def namespace
      "#{name}"
    end

    # appname is the name of the application
    # block is curried to Capistrano
    def initialize(appname)
      @name = appname
      @environments = []
      #Sauce.add_application(self) # register application
      self
    end

    # fetch environment by name
    def [](envname)
      envname = envname.name if envname.is_a?(Environment)
      @environments.find {|i| i.name == envname.to_s }
    end

    # Add/Extend an Environment for this Application
    def add_environment(envname, &block)
      env = self[envname]
      if !env
        env = Environment.new(self, envname, &block)
        @environments << env
      end
      yield env if block_given?
      return env
    end
    alias :environment :add_environment # config friendly alias


    def base_recipe
      _self = self
      lambda do
        desc "List environments"
        task :default do
          list_environments
        end
        
        desc "[internal] List environments"
        task :list_environments do
          logger.info("#{_self.name} has #{_self.environments.length} environments:\n")
          _self.environments.each do |env|
            env.find_and_execute_task("list_servers")
          end
        end
      end
    end

    # cookable Environment, put your server definitions in here
    class Environment
      include Cookable
      attr_reader :application, :name

      def namespace
        "#{application.name}:#{name}"
      end

      # app can be an Application or the name of an Application
      # envname is a name like local,staging,production
      # block is curried to capistrano_config and should contain tasks definitions 'n such
      def initialize(app, envname)
        if app.is_a?(Application)
          @application = app
        else
          appname = app.to_s
          app = Sauce.applications.find {|i| i.name == appname }
          raise ConfigError.new("Application '#{appname}' does not exist!") if !existing_app
          @application = app
        end
        @name = envname
        self
      end

      # overridden to include parrent application recipes as well
      def recipes
        (@application.recipes + @recipes).uniq
      end
      
      def base_recipe
        _self = self # for tasks relying on self inflection
        lambda do

          desc "List servers"
          task :default do
            list_servers
          end

          desc "[internal] List servers"
          task :list_servers do
            env = Sauce.current
            servers = find_servers()
            logger.info "#{env.name} (#{servers.length} server#{servers.length==1 ? '':'s'})"
            # Capistrano doesnt provide ServerDefinition.new.roles, weak.
            host_roles = {}
            env.cap_config.roles.each {|role_name, role|
              role.servers.each {|s| 
                host_roles["#{s.host}:#{s.port}"] ||= []; 
                host_roles["#{s.host}:#{s.port}"] << role_name
              }
            }
            servers.each do |s|
              roles_str = (host_roles["#{s.host}:#{s.port}"] || []).join(", ")
              logger.info "#{s.host}#{s.port ? ':'+s.port.to_s : ''}  [#{roles_str}]  #{s.options.empty? ? '' : s.options.inspect}"
            end
            logger.info("\n")
          end
          
        end # lambda
      end

    end # ::Application::Environment

  end # ::Application
end
