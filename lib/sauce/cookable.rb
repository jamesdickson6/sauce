require 'sauce'
require 'capistrano/configuration'
module Sauce
  #############################################
  # Cookable: 
  #   Mixin to allow your class to function as a Capistrano::Configuration
  #############################################
  module Cookable
    module ClassMethods
      def standard_recipes
        ['sauce/recipes/standard']
      end
    end
    def self.included(base)
      base.extend(ClassMethods)

      base.class_eval do
        attr_reader :namespace
        attr_reader :recipes # other recipes to cook 
        attr_reader :cooked
        # Capistrano::Configuration for this object
        # Generated based on the current Sauce::Configuration
        def cap_config
          @cap_config ||= Sauce.instance.new_capistrano_config()
        end
        alias :capistrano :cap_config

        # Override this in your class with a recipe that accepts itself
        # must return a Proc
        def base_recipe()
          warn "#{self} hasn't been overridden to return a Proc!!"
          lambda {
            # put your capistrano config and tasks in here
          }
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
        #   load(:proc => lambda {...}):
        #     Load the proc in the context of the configuration.
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


        # load capistrano configuration with recipes
        # if a block is passed, it is cooked too
        def cook(&block)
          the_recipes = [
                         self.class.standard_recipes,
                         self.base_recipe,
                         self.recipes,
                         (block_given? ? block : nil)
                        ].flatten.compact.uniq
          the_recipes.each do |r|
            if r.is_a?(Proc)
              self.cap_config.load(:proc => r)
            else # assume recipe filename
              self.cap_config.load(:file => r)
            end
          end
          @cooked = true
          self.cap_config
        end

        # serve it up
        def serve
          cook unless @cooked
          Sauce.current = self
          self.cap_config
        end

        # Proxy for capistrano config method
        def execute_task(task)
          cur_sauce = Sauce.current
          begin
            self.serve
            self.cap_config.execute_task(task)
          ensure
            cur_sauce.serve if cur_sauce
          end
        end

        # Proxy for capistrano config method
        def find_and_execute_task(task, hooks={})
          cur_sauce = Sauce.current
          begin
            self.serve
            self.cap_config.find_and_execute_task(task, hooks)
          ensure
            cur_sauce.serve if cur_sauce
          end
        end

      end
    end

  end
end
