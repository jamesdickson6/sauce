require 'capistrano'
require 'forwardable'
require 'sauce/cookable'
require 'sauce/configuration'
# Cook application recipes and serve them to Capistrano
module Sauce
  extend Forwardable
  # extension for finding configuration files
  SAUCE_FILE_EXTENSION = ".sauce".freeze
  SAUCE_FILE_DEPTH = 2.freeze
  # Load paths for sauce recipes
  RECIPE_LOAD_PATHS = [File.expand_path(File.join(File.dirname(__FILE__))),
                       File.expand_path(File.join(File.dirname(__FILE__), "sauce/recipes")),
                       File.join(Gem::Specification.find_by_name("capistrano").gem_dir, "lib")
                      ].freeze

  # Indicates a problem with sauce configuration
  class ConfigError < StandardError; end

  # Holds current Sauce::Configuration, you'll probably never use more than one
  def instance
    Thread.current[:sauce_configuration] ||= Configuration.new
  end

  def instance=(sauce_conf) #:nodoc:
    raise ArgumentError.new("Sauce.instance= expects a Configuration and got a #{cookable.class} instead!") unless sauce_conf.is_a?(Configuration)
    Thread.current[:sauce_configuration] = sauce_conf
  end

  # some friendly module methods, delegated to current config
  def_delegators :instance, :applications, :[], :application, :brew, :cook, :serve
  module_function :instance, :applications, :[], :application, :brew, :cook, :serve


  # Holds current Sauce::Cookable that's been served
  def current
    Thread.current[:cookable] ||= instance
  end

  def current=(cookable) #:nodoc:
    raise ArgumentError.new("Sauce.current= expects a Cookable and got a #{cookable.class} instead!") unless cookable.is_a?(Cookable)
    Thread.current[:cookable] ||= cookable
  end
  # Proxy to currently served Capistrano config
  def capistrano
    current.cap_config
  end
  module_function :current, :current=, :capistrano

  # some well-known friendly module methods, delegated to current capistrano config
  def_delegators :capistrano, :find_and_execute_task
  module_function :capistrano, :find_and_execute_task

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

  module_function :find_sauce_files, :new_capistrano_config

end
