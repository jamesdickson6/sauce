require 'sauce/cookable'
require 'sauce/application'
require 'capistrano/configuration'
require 'capistrano/logger'
module Sauce  
  #############################################
  # Configuration: 
  #   Container to hold your Cookables Eg. Applications and their Environments
  #   You can cook and serve this too!  That is what the CLI does.
  #############################################
  class Configuration
    include Cookable
    # (Default) Extension for finding sauce files
    SAUCE_FILE_EXTENSION = ".sauce".freeze
    # (Default) How deep to look for sauce files
    SEARCH_DEPTH = 2.freeze

    # Load paths for recipe files.
    # Since people will want to include their own recipes,
    # Require the recipes path to be specified as follows:
    #  load 'capistrano/recipes/cool'
    #  load 'sauce/recipes/awesome'
    # The following should work as well: (untested)
    #  load 'some/recipe/relative/to/your/saucefilesome' 
    @@load_paths = [File.expand_path(File.join(File.dirname(__FILE__), "../")),
                    File.join(Gem::Specification.find_by_name("capistrano").gem_dir, "lib")
                   ].freeze
    def self.load_paths
      @@load_paths ||= []
    end

    attr_reader :applications, :sauce_files

    def namespace
      ""
    end

    def initialize(opts={})
      @opts = opts || {}
      @opts[:basedir] ||= Dir.pwd
      @opts[:search_depth] = (opts[:search_depth] || SEARCH_DEPTH).to_i
      @opts[:sauce_file_extension] = opts[:sauce_file_extension] || SAUCE_FILE_EXTENSION
      @sauce_files = self.find_sauce_files()
      @applications = []
      return self
    end

    # find sauce files, avoid looking too deep
    def find_sauce_files(cwd=@opts[:basedir], depth=@opts[:search_depth], file_ext=@opts[:sauce_file_extension])
      files = []
      (0..depth).each do |i|
        prefix = "*/"*i
        files << Dir.glob(File.join(cwd, "#{prefix}*#{file_ext}"))
      end
      return files.flatten.uniq
    end

    # returns a new Capistrano::Configuration
    def new_capistrano_config(opts=@opts)
      c = Capistrano::Configuration.new(opts)
      # NOTE: Capistrano::Logger constant values are opposite of Logger  ....goofy
      c.logger.level = opts[:log_level] || Capistrano::Logger::DEBUG
      @@load_paths.each {|d| c.load_paths << d }
      Array(opts[:load_paths]).flatten.each {|d| c.load_paths << d } if opts[:load_paths]
      return c
    end    

    alias :super_cook :cook
    def cook
      # define applications via .sauce files
      @sauce_files.each do |f|
        #puts "loading sauce: #{f}"
        Kernel.load f #ruby's plain old load method to eval .sauce files
      end
      # cook everything in this config
      applications.each do |app|
        app.cook
        app.environments.each do |env|
          env.cook
        end
      end
      super_cook
    end

    # fetch cookable by namespace
    # E.g. ["appname"] or ["appname:envname"]
    def [](ns)
      namespaces = ns.to_s.split(":").compact
      rtn = @applications.find {|a| a.name == namespaces.shift }
      begin
        while (!namespaces.empty?)
          rtn = rtn[namespaces.shift]
        end
      rescue
        return nil
      end
      return rtn
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


    def base_recipe
      _self = self # for tasks relying on self inflection
      lambda do

        # This might be better off removed so that `sauce` doesn't spew everything
        desc "[internal] List applications and their environments"
        task :default do
          list
        end

        desc "List all applications and their environments"
        task :list do
          num_apps = _self.applications.length
          if num_apps == 0
            logger.important "Found 0 applications with sauce...  Try saucify..."
          else
            logger.info "Found #{num_apps} application#{num_apps==1 ? '':'s'} with sauce!"
            _self.applications.each do |app|
              app.find_and_execute_task("list_environments")
            end
          end
        end

        # Stub out tasks for each app:env
        # NOTE: These tasks are blank since they will never be executed
        #  The configuration will serve the application's config when it's tasks are invoked..
        #  These are simply here so they can be seen with `sauce -T`
        _self.applications.each do |app|

          namespace app.name do
            [:default].each do |t_name|
              desc app.capistrano.tasks[t_name] ? app.capistrano.tasks[t_name].description : "missing"
              task t_name do
              end
            end

            app.environments.each do |env|
              namespace env.name do

                [:default].each do |t_name|
                  desc env.capistrano.tasks[t_name] ? env.capistrano.tasks[t_name].description : "missing"
                  task t_name do
                  end
                end

                
                #env.hosts.each do |host|
                #  namespace host.name do
                #    [:default].each do |t_name|
                #      desc host.capistrano.tasks[t_name] ? host.capistrano.tasks[t_name].description : "missing"
                #      task t_name do
                #      end
                #    end
                #  end
                #end

                 end
              end

            end

          end


          desc <<-ENDSTR
[internal]
Done locally..
Attempts to pull down the latest code for each .sauce file we found.
Only supports git and svn right now.
!!WARNING!! Be careful not to run this over your working directories..you don't want to invoke a merge!
ENDSTR
          task :pull do
            cur_dir = Dir.pwd
            Sauce.instance.sauce_files.each do |fn|
              dir = File.dirname(fn)
              begin
                if File.exists?(File.join(dir, ".git"))
                  run_locally("cd #{dir} && git pull")
                elsif File.exists?(File.join(dir, ".svn"))
                  run_locally("cd #{dir} && svn up")
                else
                  say "No source control found for #{fn}"
                end
              rescue => e
                say "Encountered a problem!"
                logger.important(e)
              ensure
                Dir.chdir(cur_dir)
              end
            end
          end

        end # lambda
      end

    end # ::Configuration


  end
