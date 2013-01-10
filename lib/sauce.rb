require 'capistrano'
require 'forwardable'
require 'sauce/cookable'
# Cook application recipes and serve them to Capistrano
module Sauce
  # extension for finding configuration files
  SAUCE_FILE_EXTENSION = ".sauce".freeze
  SAUCE_FILE_DEPTH = 2.freeze
  # Load paths for sauce recipes
  RECIPE_LOAD_PATHS = [File.expand_path(File.join(File.dirname(__FILE__))),
                        File.expand_path(File.join(File.dirname(__FILE__), "sauce/recipes"))].freeze
  # standard recipes to load
  SAUCE_RECIPES = ["sauce.tasks.rb"].freeze

  # Indicates a problem with sauce configuration
  class ConfigError < StandardError; end

  # holds current Sauce configuration, rarely will you need more more than one of these
  def instance
    Thread.current[:sauce_configuration] ||= Configuration.new
  end

  # some friendly module methods, delegated to current config
  extend Forwardable
  def_delegators :instance, :applications, :[], :application, :brew, :cook, :serve
  module_function :instance, :applications, :[], :application, :brew, :cook, :serve

  # find sauce files, avoid looking too deep
  def find_sauce_files(cwd=Dir.pwd, depth=SAUCE_FILE_DEPTH)
    files = []
    (0..depth).each do |i|
      prefix = "*/"*i
      files << Dir.glob(File.join(cwd, "#{prefix}*#{SAUCE_FILE_EXTENSION}"))
    end
    return files.flatten.uniq
  end
  def new_capistrano_config(opts={})
    # JD: Should maybe parse ARGV here?
    c = Capistrano::Configuration.new(opts)
    RECIPE_LOAD_PATHS.each {|d| c.load_paths << d }
    return c
  end

  # Capistrano::Configuration makes this method private..so here it is
  def find_capistrano_recipe(conf, file)
    conf.load_paths.each do |path|
      ["", ".rb"].each do |ext|
        name = File.join(path, "#{file}#{ext}")
        return name if File.file?(name)
      end
    end
    raise LoadError.new("no such file to load -- #{file}")
  end
  
  # load tasks block within a capistrano configuration, under a certain namespace
  #  inject_capistrano_config(config, "coolApp:env1", :file => "some_recipe") 
  #  inject_capistrano_config(config, "coolApp:env1", :proc => some_proc)
  # JD: recursive solution would be cooler
  def inject_capistrano_config(conf, namespaces, opts={})
    raise ArgumentError.new("Expected a Capistrano::Configuration and got #{conf.class} instead") unless conf.is_a?(Capistrano::Configuration)
    namespaces = namespaces.is_a?(Array) ? namespaces.dup : namespaces.to_s.split(":")
    cur_ns = conf
    # puts "Building Capistrano Config for namespace #{namespaces.join(':')}"
    while (!namespaces.empty?)
      ns = namespaces.shift
      next if !ns || ns.to_s.strip == ""
        cur_ns.namespace ns.to_sym do
          # build namespace
        end
      cur_ns = cur_ns.namespaces[ns.to_sym]
    end

    # inject recipe/proc
    if opts[:proc]
      cur_ns.namespace(ns.to_sym, &opts[:proc]) # add block to namespace
    elsif opts[:file]
      recipe_file = find_capistrano_recipe(conf, opts[:file])
      cur_ns.instance_eval(File.read(recipe_file))
    end
    return conf
  end

  module_function :find_sauce_files, :new_capistrano_config, :inject_capistrano_config, :find_capistrano_recipe

  
  # container for saucified applications
  #
  class Configuration
    include Cookable
    attr_reader :applications, :sauce_files

    def namespace
      ""
    end

    def initialize(opts={})
      @opts = opts || {}
      @applications = []
      # find saucified apps under current directory by default
      @opts[:dir] ||= Dir.pwd
      @sauce_files = Sauce.find_sauce_files(@opts[:dir])
      return self
    end

    alias :super_cook :cook
    def cook
      # define applications via .sauce files
      @sauce_files.each do |f|
        #puts "loading sauce: #{f}"
        Kernel.load f #ruby's plain old load method to eval .sauce files
      end
      # load default sauce recipes (for inspecting applications)
      self.load(SAUCE_RECIPES)
      # cook application environments
      applications.each do |app|
        app.cook
        app.environments.each do |env|
          env.cook
        end
      end
      super_cook
    end

    # fetch application by name
    def [](appname)
      appname = appname.name if appname.is_a?(Application)
      @applications.find {|a| a.name == appname.to_s }
    end

    # Create/Extend an Application in this configuration
    def add_application(appname)
      app = self[appname]
      if !app
        app = Application.new(appname)
        @applications << app
      end
      yield app if block_given?
      return app
    end
    alias :brew :add_application # config friendly alias
    alias :application :add_application # config friendly alias


  end


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

      # overridden to include application recipes as well
      def recipes
        (@application.recipes + @recipes).uniq
      end

    end

  end

end
