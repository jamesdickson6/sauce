require 'capistrano'
require 'forwardable'
require 'sauce/cookable'
require 'sauce/configuration'
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
    # build namespace
    namespaces = namespaces.is_a?(Array) ? namespaces.dup : namespaces.to_s.split(":")
    cur_ns = conf
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
      cur_ns.instance_eval(&opts[:proc]) # add block to namespace
    elsif opts[:file]
      recipe_file = find_capistrano_recipe(conf, opts[:file])
      cur_ns.instance_eval(File.read(recipe_file))
    end
    return conf
  end

  module_function :find_sauce_files, :new_capistrano_config, :inject_capistrano_config, :find_capistrano_recipe

end
