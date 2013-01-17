require 'sauce'
require 'sauce/cookable'
module Sauce
  # cookable application and its environments
  #
  class Application
    STANDARD_RECIPES = ["sauce/recipes/application"].freeze
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


    class Environment
      STANDARD_RECIPES = ["sauce/recipes/application_environment"].freeze
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

      # overridden to include application recipes as well
      def recipes
        (@application.recipes + @recipes).uniq
      end

    end

  end
end
