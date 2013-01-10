require 'sauce'
require 'capistrano/configuration'
module Sauce
  # Mix this in to your class if you want it to be able to load a Capistrano configuration
  module Cookable

    module ClassMethods
    end

    def self.included(base)
      base.extend(ClassMethods)

      base.class_eval do
        attr_reader :namespace
        attr_reader :cap_config
        attr_reader :recipes
        attr_reader :cooked

        # capistrano configuration for this object
        def cap_config
          @cap_config ||= Sauce.new_capistrano_config()
        end

        # Array of recipes in the form of a String (filename) or Procs
        def recipes
          @recipes ||= []
        end

        # This is meant to mimic the behavior of Capistrano::Configuration.load
        # It actually just stores recipes for cooking (loading into configuration) later on
        #
        # Usage:
        #
        #   load("recipe"):
        #     Look for and load the contents of 'recipe.rb' into this
        #     configuration.
        #
        #   load(:file => "recipe"):
        #     same as above
        #
        #   load(:proc => "recipe"):
        #     same as above
        #
        #   load { ... }
        #     Load the block in the context of the configuration.
        def load(*args, &block)
          @recipes ||= []
          options = args.last.is_a?(Hash) ? args.pop : {}
          [:proc, :file, :recipe].each do |k|
            @recipes << options[k] if options[k] && !@recipes.include?(k)
          end
          args.flatten.each do |arg|
            @recipes << arg if arg.is_a?(String) || arg.is_a?(Proc)
          end
          @recipes << block if block_given?
          self
        end
        alias :add_recipe :load

        # load configuration
        def cook
          self.recipes.each do |recipe|
            if recipe.is_a?(Proc)
              Sauce.inject_capistrano_config(self.cap_config, self.namespace, :proc => recipe)
            else # assume recipe filename
              Sauce.inject_capistrano_config(self.cap_config, self.namespace, :file => recipe)
            end
          end
          @cooked = true
          self.cap_config
        end

        # serve this Configuration to Capistrano
        def serve
          cook unless @cooked
          Capistrano::Configuration.instance = self.cap_config
        end

      end
    end

  end
end
