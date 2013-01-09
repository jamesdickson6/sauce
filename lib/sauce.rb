require 'rubygems'
require 'capistrano'

# Cook application recipes and serve them to Capistrano
module Sauce
  # extension for finding configuration files
  SAUCE_FILE_EXTENSION = ".sauce".freeze
  SAUCE_FILE_DEPTH = 3
  # Load paths for sauce recipes
  RECIPES_LOAD_PATHS = [File.expand_path(File.join(File.dirname(__FILE__))),
                        File.expand_path(File.join(File.dirname(__FILE__), "sauce/recipes"))].freeze
  # standard recipes to load
  SAUCE_RECIPES = ["sauce.tasks.rb"].freeze

  class ConfigError < StandardError; end

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
    RECIPES_LOAD_PATHS.each {|d| c.load_paths << d }
    return c
  end

  # load tasks block within a capistrano configuration, under a certain namespace
  #  inject_capistrano_config(config, "coolApp:env1", :file => "some_recipe") 
  #  inject_capistrano_config(config, "coolApp:env1", :proc => some_proc)
  # JD: recursive solution would be cooler
  def inject_capistrano_config(config, namespaces, opts={})
    raise ArgumentError.new("Expected a Capistrano::Configuration and got #{config.class} instead") unless config.is_a?(Capistrano::Configuration)
    namespaces = namespaces.is_a?(Array) ? namespaces.dup : namespaces.to_s.split(":")
    cur_ns = config
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
      recipe_filepath = nil
      config.load_paths.each do |path|
        ["", ".rb"].each do |ext|
          name = File.join(path, "#{opts[:file]}#{ext}")
          if File.file?(name)
            recipe_filepath = name
          end
        end
      end
      raise LoadError, "no such file to load -- #{file}" if !recipe_filepath
      cur_ns.instance_eval(File.read(recipe_filepath))
    end
    return config
  end

  module_function :find_sauce_files, :new_capistrano_config, :inject_capistrano_config

  def instance
    Thread.current[:sauce_configuration] ||= Configuration.new
  end

  # some friendly module methods, delegated to current config
  def applications; instance.applications; end
  def [](appname); instance[appname]; end
  def application(appname, &block); instance.brew(appname, &block); end
  def brew(appname, &block); instance.application(appname, &block); end # alias for application
  def cook; instance.cook; end
  def serve; instance.serve; end
  module_function :instance, :applications, :[], :application, :brew, :cook, :serve

  # container for saucified applications
  class Configuration
    attr_reader :applications, :sauce_files
    attr_reader :capistrano_config

    def initialize(opts={})
      @opts = opts || {}
      @applications = []
      @capistrano_config = Sauce.new_capistrano_config()
      # find saucified apps under current directory by default
      @opts[:dir] ||= Dir.pwd
      @sauce_files = Sauce.find_sauce_files(@opts[:dir])
      return self
    end

    # load sauce files for this configuration and generate capistrano tasks
    def cook
      @sauce_files.each do |f|
        #puts "loading sauce: #{f}"
        load f #ruby's plain old load method to eval .sauce files
      end
      # load standard recipes
      SAUCE_RECIPES.each { |f| @capistrano_config.load(:file => f) }
      # Cook the application environments
      applications.each {|app| app.environments.each {|env| env.cook } }
      @cooked = true
      self
    end

    # serve this Configuration to Capistrano
    def serve
      cook if !@cooked
      Capistrano::Configuration.instance = @capistrano_config
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
    attr_reader :name, :environments, :cap_procs, :cap_recipes
    # appname is the name of the application
    # block is curried to Capistrano
    def initialize(appname)
      @name = appname
      @environments = []
      @cap_recipes = []
      @cap_procs = []
      #Sauce.add_application(self) # register application
      self
    end

    # store recipe file for cooking later
    def recipe(filename)
      @cap_recipes << filename unless @cap_recipes.include?(filename)
    end

    # store block for cooking later
    def capistrano(&block)
      @cap_procs << block if block
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
      attr_reader :name, :application, :cap_recipes, :cap_procs
      attr_reader :capistrano_config
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
        @capistrano_config = Sauce.new_capistrano_config()
        @cap_recipes = []
        @cap_procs = []
        self
      end

      # store recipe file for cooking later
      def recipe(filename)
        @cap_recipes << filename unless @cap_recipes.include?(filename)
      end

      # store block for cooking later
      def capistrano(&block)
        @cap_procs << block if block
      end


      # cook Capistrano configuration/recipes for this environment
      def cook
        ns = "#{application.name}:#{name}"
        # load Application recipes
        application.cap_recipes.each do |cap_recipe|
          Sauce.inject_capistrano_config(@capistrano_config, ns, :file => cap_recipe)
        end
        # load Application configs
        application.cap_procs.each do |cap_block|
          Sauce.inject_capistrano_config(@capistrano_config, ns, :proc => cap_block)
        end
        # load Environment recipes
        @cap_recipes.each do |cap_recipe|
          Sauce.inject_capistrano_config(@capistrano_config, ns, :file => cap_recipe)
        end
        # load Environment configs
        @cap_procs.each do |cap_block|
          Sauce.inject_capistrano_config(@capistrano_config, ns, :proc => cap_block)
        end
        @cooked = true
        @capistrano_config
      end

      # serve this Configuration to Capistrano
      def serve
        cook if !@cooked
        Capistrano::Configuration.instance = @capistrano_config
      end

    end

  end

end
