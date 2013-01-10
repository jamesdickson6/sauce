require 'sauce'
require 'sauce/cookable'
require 'sauce/application'
require 'capistrano'
module Sauce  
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


end
