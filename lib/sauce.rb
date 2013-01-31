require 'capistrano'
require 'forwardable'
require 'sauce/cookable'
require 'sauce/configuration'
require 'sauce/software'
#############################################
# Sauce
#   Cook application:environment Capistrano recipes and serve them up
#############################################
module Sauce
  extend Forwardable

  # Indicates a problem with sauce configuration
  class ConfigError < StandardError; end

  #############################################
  # Accessing the current Sauce::Configuration
  #############################################

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


  #############################################
  # Accessing the current Cookable
  #############################################


  # Holds current Sauce::Cookable that has been served
  def current
    Thread.current[:cookable] ||= instance
  end

  # don't call this, just call .serve() on your Cookable
  def current=(cookable) #:nodoc:
    raise ArgumentError.new("Sauce.current= expects a Cookable and got a #{cookable.class} instead!") unless cookable.is_a?(Cookable)
    Thread.current[:cookable] = cookable
  end

  # some well-known friendly module methods, delegated to current capistrano config
  def_delegators :current, :find_and_execute_task, :execute_task
  module_function :current, :current=, :find_and_execute_task, :execute_task



end
