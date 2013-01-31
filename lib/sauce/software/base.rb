require 'sauce/software'
require 'sauce/software/software_dependencies'
require 'capistrano/configuration'
require 'sauce/command_result'
require 'forwardable'
module Sauce
  module Software
    
    ########################################################################    
    # Abstract superclass for defining installable/runnable software.
    #
    # Software has a Capistrano::Configuration it uses to execute remote commands.
    # It also acts like a configuration, you can call fetch(),set(), etc on it directly.
    #
    # Instances of these objects can be used to make you deployment recipe's concise and simple.
    #
    # Software can have software_dependencies (other Software)
    # Software can be package_manager, which is deferred to for installing
    #
    # Most software attributes can be configured at the class level and overridden in instances
    ########################################################################
    class Base
      def self.software_name; @software_name; end # set this!
      def self.software_version; @software_version; end
      def self.software_command; @software_command || self.software_name; end
      # This should be a Hash like :key => description of required variable
      def self.required_options; @required_options || {}; end # no inheritance here
      
      include SoftwareDependencies

      attr_accessor :name, :version, :command, :run_via
      attr_accessor :package_manager
      attr_reader :configuration
      
      # act like a configuration!
      extend Forwardable
      def_delegators :configuration, :fetch, :set, :logger, :say, :ask
      def_delegators :configuration, :find_servers, :with_env, :with_role, :with_roles, :with_hosts, :with_host, :with_each_host, :with_shellescape
      def_delegators :configuration, :upload
      # force the use of protected run_command() for now...
      # def_delegators :configuration, :invoke_command, :run, :sudo, :try_sudo 


      # +configuration+ Capistrano::Configuration for this software to live in..
      # +attrs+ : Hash of attributes to override class default values
      # * +name+: name of software, used for checking and installing. Default comes from class.
      # * +command+: executable command. used for executing.  Default comes from class, else == name.
      # * +version+: version. Default is nil (no specific version required)
      # * +run_via+: This can be set to :sudo if needed. The preferred default is just to execute as the current user.
      # * +package_manager+: Check/Install with some other software. Default comes from configuration or is nil (must know how to check/install itself)
      # * +service_manager+: Start/Stop with some other software. Default comes from configuration or is nil (must know how to check/install itself)      
      # * +*+: any other instance variable available via attr=
      def initialize(configuration, attrs={})
        raise ArgumentError.new("#{self.class} must be instantiated with a Capistrano::Configuration, not (#{configuration.class}) #{configuration}") unless configuration.is_a?(Capistrano::Configuration)
        raise ArgumentError.new("#{self.class} must be instantiated with a Hash of options, not (#{attrs.class}) #{attrs}") unless attrs.is_a?(Hash)
        @configuration = configuration
        @name = self.class.software_name
        @command = self.class.software_command || @name
        @version = self.class.software_version
        attrs.each { |k,v| self.send("#{k}=",v) if self.respond_to?("#{k.to_s}=") }
        self.class.required_options.each { |k, desc| raise ArgumentError.new("(#{self.class}) #{self} requires option #{k.inspect} !! #{desc}") if self.send(k).nil? && !attrs.key?(k) }
        self
      end

      def inspect
        "#{self.to_s}"
      end
      def to_s
        "#{@name} #{@version}".strip
      end
      
      def name
        @name or raise NotImplementedError.new("name is not implemented by #{self.class.name}")
      end

      # command for running this software.
      # This can be overridden by setting +<name>_command+ in your configuration
      def command
        @command or raise NotImplementedError.new("command is not implemented by #{self.class.name}")
      end

      # Default is :run, alternative is :sudo
      def run_via
        @run_via || :run
      end

      # package_manager is optional, software can know how to install itself however it wants..
      # override this in your subclass or rely on configuration
      # it should return an instance of Software::PackageManager or false to indicate No Package Manager
      def package_manager
        (!@package_manager.nil? ? @package_manager : (fetch("#{name}_package_manager", nil) || fetch(:default_package_manager, nil)))
      end      
      def package_manager=(software)
        raise ArgumentError.new("Expected a PackageManager and got a (#{package_manager.class}) #{package_manager} instead.") unless software==false || software.is_a?(PackageManager)
        raise ArgumentError.new("#{name} set package_manager=(itself) #{self.class}") if software.class == self.class
        @package_manager = software
      end


      ########################################################################
      # TODO: Eliminate need for run_<method> implementation in subclass
      # Sauce::Software::Base interface 2.0
      # options are curried to run_command(command, options, &block)
      ########################################################################
=begin      
      # include Installable to define the following
      def installable?(options={}, &block); raise NotImplementedError.new("installable?() is not implemented by #{self.class.name}"); end      
      def installed?(options={}, &block); raise NotImplementedError.new("installed?() is not implemented by #{self.class.name}"); end
      def check_command(); "which #{self.command}" end # default way to do
      def check(options={}, &block); raise NotImplementedError.new("check() is not implemented by #{self.class.name}"); end
      def install(options={}, &block); raise NotImplementedError.new("install() is not implemented by #{self.class.name}"); end
      def uninstall(options={}, &block); raise NotImplementedError.new("uninstall() is not implemented by #{self.class.name}"); end      

      # include SoftwareDependencies to define the following
      def install_software_dependencies(options={}, &block); raise NotImplementedError.new("install_software_dependencies() is not implemented by #{self.class.name}"); end
      def software_dependencies_installed?(options={}, &block); raise NotImplementedError.new("software_dependencies_installed?() is not implemented by #{self.class.name}"); end      
      def missing_software_dependencies(options={}, &block); raise NotImplementedError.new("missing_software_dependencies() is not implemented by #{self.class.name}"); end
      def depends_on?(options={}, &block); raise NotImplementedError.new("depends_on?() is not implemented by #{self.class.name}"); end

      # include Service to define the following
      def running?(options={}, &block); raise NotImplementedError.new("running?() is not implemented by #{self.class.name}"); end
      def start(options={}, &block); raise NotImplementedError.new("start() is not implemented by #{self.class.name}"); end
      def stop(options={}, &block); raise NotImplementedError.new("stop() is not implemented by #{self.class.name}"); end
      def restart(options={}, &block); raise NotImplementedError.new("restart() is not implemented by #{self.class.name}"); end
      def reload(options={}, &block); raise NotImplementedError.new("reload() is not implemented by #{self.class.name}"); end
      
=end
            
      ########################################################################
      # Software Interface 1.0
      # options are curried to run_command(options, &block)
      ########################################################################
      
      
      ########################################################################
      # Checking if this software and it's dependencies are installed
      ########################################################################

      # it should return status code other than 0 to indicate it IS installed
      # override this in your class if applicable      
      def check_command
        "which #{command}"
      end

      # defers to package manager if set, else run #check_command
      # override this in your class if necessary, return a CommandResult
      def run_check(options={}, &block)
        if self.package_manager
          return self.package_manager.check(options.merge(:software => self))
        elsif check_command
          return run_command(check_command(), options, &block)
        else
          raise NotImplementedError.new("We don't know how to check (#{self.class.name}) #{self.name}! Override run_check() check_command() or try setting :package_manager")
        end
      end
      

      # check whether this software and it's dependencies are installed
      # The +options+ and block are curried to #run_command
      # returns true if all checks pass, else false
      def check(options={}, &block)
        options = options.dup
        bad_hosts = []
        # do this sequentially so we can check cache and print as we go
        with_each_host(options) do |host|
          # Check cache for installation status
          cache_val = installed_in_cache?(host)
          if !cache_val.nil?
            logger.debug("#{host}: Software Installation Check: #{self}".ljust(80) + (cache_val ? green("PASS") : red("FAIL")) + " (cache)") unless options[:quiet]
            bad_servers << host if !cache_val
            next
          end
          
          # Check if this software's dependencies are installed
          missing_dependencies = options[:skip_dependencies] ? [] : self.missing_software_dependencies(options.merge(:quiet => true, :raise => false))
          
          # Check if this software is installed
          result = run_check(options.merge(:quiet => true, :raise => false), &block)
          
          is_installed = (result.success? && missing_dependencies.empty?)
          bad_hosts << host if !is_installed
          add_host_software_cache(host, is_installed)
          
          # Print output
          logger.info("#{host}: Software Installation Check: #{self}".ljust(80) + (is_installed ? green("PASS") : red("FAIL")) + (missing_dependencies.empty? ? "" : " (missing dependencies: #{missing_dependencies.join(', ')})")) unless options[:quiet]          
        end

        # Return or raise
        return true if bad_hosts.empty?
        raise Error.new("#{self} is not installed on the following hosts: #{bad_hosts.join(', ')}") if options[:raise]

        return false
      end
      
      alias :installed? :check

      # check and raise error upon failure
      def check!(options={})
        check(options.merge(:raise => true))
      end

      ########################################################################
      # Installing this software
      ########################################################################
      
      def install_command
        nil
      end

      # override this in your class if necessary
      # the default behavior is to defer to package manager
      def run_install(options={}, &block)
        if self.package_manager
          return self.package_manager.install(options.merge(:software => self))
        elsif install_command
          return run_command(install_command(), options, &block)
        else
          raise NotImplementedError.new("We don't know how to install (#{self.class.name}) #{self.name}! Override run_install(), install_command() or try setting a package_manager")
        end
      end
      
      # install this software on each host sequentially
      # nothing is done is done if the software is already installed
      def install(options={})
        bad_servers = []
        with_each_host(options) do |host|
          server = server.to_s #convert ServerDefinition to host:port
          # Already installed?
          if self.installed?(options.merge(:hosts => server, :quiet => true, :raise => false))
            logger.info("#{host}: Software Installation: #{self}".ljust(80) + green("ALREADY INSTALLED")) unless options[:quiet]
            next
          end

          delete_host_software_cache(host)
          
          logger.info("#{host}: Installing #{self}...")

          # Check if dependencies are installed, and if not, go ahead and install them
          self.missing_software_dependencies.each do |s|
            logger.info("#{host}: Installing missing dependency: #{s}...")
            rtn = s.install(options)
            if !rtn.success?
              logger.info("#{host}: Software Installation: #{s}".ljust(80) + red("FAILED") + "(Failed to install dependency #{s})") unless options[:quiet]
              abort("Aborting...")
            end
          end

          # Do the install
          rtn = run_install(options.merge(:hosts => host, :raise => false))
          
          add_host_software_cache(host, rtn.success?)
          logger.info("#{host}: Software Installation: #{self}".ljust(80) + (rtn.success ? green("SUCCESS") : red("FAILED"))) unless options[:quiet]
        end # each host

        return true if bad_servers.empty?
        raise Error.new("#{self} install failed on the following hosts: #{bad_servers.join(', ')}") if options[:raise]
        return false

      end
        
      # uninstall this software
      # subclasses should set their package_manager, install_via or override this method
      def uninstall
        raise NotImplementedError.new("uninstall is not implemented by #{self.class.name}")
      end

      # upgrade this software (like gem update --system)
      # subclasses should set their package_manager, install_via or override this method
      def upgrade
        raise NotImplementedError.new("upgrade is not implemented by #{self.class.name}")
      end


      protected

      ########################################################################
      # Execute a command on remote server(s)
      #
      # This exists because Capistrano's +run+, +invoke_command+,etc has a crumby return value (always nil).
      # This method does conform to #invoke_command (cmd, options={}) {|ch, stream, out| }
      # All of the #invoke_command options are supported (curried),
      # However, it returns a useful CommandResult and has some extra handy options.
      # 
      # By default, this executes remotely on all servers scoped by currently executing task.
      # The command is executed in parallel on those servers by default.  See +sequential+
      #
      # Hosts to execute on can be further scoped by passing the options +hosts+ or +roles+.  
      #
      # cmd: String of the shell command to run      
      # options (Hash) curried to Capistrano's #invoke_command so all of it's options are supported.
      # * +sudo+ Run the command as sudo? Default is the class level value.
      #          Try not to use sudo (false by default)
      # * +parallel+ Default is true. Pass false to execute sequentially on each host.  
      #              This can be important for print/capturing sensitive output.
      # * +echo+: log stderr and stdout. Default is false.
      # * +echo_out+: log stdout. Default is false.
      # * +echo_err+: log stderr. Default is false.
      # * +raise+ Default is false.  pass true to raise a CommandError instead of returning.
      # * +bool+ return boolean true/false (success value) instead of a CommandResult
      # * +shellescape+ Whether or not to escape commands for shell. Default is true.
      #                 This is usfeful if you Capistrano is munging your fancy shell command. Maybe false should be the default?
      # block: Block is curried to #run and should accept |ch,stream,out,result|
      #       If a block is passed, it's (last) return value will be the value of the result.success
      #       This is handy if you need to evaluate some text and not just rely on exit status 0
      #       NOTE: Your block may be executed multiple times, if there is lots of output
      #
      # returns: CommandResult instance or raises CommandError if +raise+ is true.
      def run_command(cmd, options={}, &result_block)
        #logger.debug("run_command(\"#{cmd}\", #{options.inspect})")
        options = options.dup
        via = options.delete(:via) || self.run_via || :run # run or sudo ?
        result = CommandResult.new

        # command isn't going to run!
        the_servers = find_servers(options)
        if the_servers.empty?
          msg = "No hosts found for ROLES=[#{ENV['ROLES']}], HOSTS=[#{ENV['HOSTS']}] #{self.to_s} options=#{options.inspect}"
          logger.important(msg)
          result = CommandResult.new({:success => false})
          raise CommandError.new(msg, result) if options[:raise]
          return result
        end
        
        # proc to generate CommandResult (capturing channel, output and such)
        # for each the host command is executing on
        # this yields the mutable result to a block if given
        capture_proc = lambda { |ch,stream,out|
          # store/overwrite result for each host
          result.with_host_result(ch[:server]) do |host_result|
            if stream == :err && (options[:echo] || options[:echo_err])
              logger.info "#{ch[:server]} : #{red('err')} : #{out}"
            elsif stream == :err && (options[:echo] || options[:echo_out])
              logger.info "#{ch[:server]} : out : #{out}"
            end
            host_result.command = cmd
            host_result.channel = ch # exit status will be in here after the channel closes
            host_result.host = ch[:server]
            host_result.out = out
            host_result.err = out if stream == :err
            if result_block
              result_block.call(ch, stream, out, host_result)
            end
            host_result # return value not used
          end

        }
        # enable/disable global shellescape setting, true by default
        with_shellescape(!options.has_key?(:shellescape) || options[:shellescape]) do
          # execute in parallel (default)
          if options[:parallel] != false && options[:sequential] != true
            begin
              configuration.invoke_command(cmd, options, &capture_proc)
            rescue Capistrano::CommandError => e
              logger.important(magenta("ERROR: #{e.inspect}")) unless options[:quiet]              
              # the capture_proc is never run if the command just exited with 0 and no output
              e.hosts.each {|h|
                result << {:host => h, :command => cmd, :success => false} unless result.hosts.include?(h)
              }
            end
          else # execute sequentially
            with_each_host(options) do |host|
              begin
                configuration.invoke_command(cmd, options.merge(:hosts =>host), &capture_proc)
              rescue Capistrano::CommandError => e
                logger.important(magenta("ERROR: #{e.inspect}")) unless options[:quiet]
                # the capture_proc is never run if the command just exited with 0 and no output
                e.hosts.each {|h|
                  result << {:host => h, :command => cmd, :success => false} unless result.hosts.include?(h)
                }
              end
            end
          end
        end
                
        if !result.success && options[:raise]
          raise CommandError.new("#{cmd} failed on hosts: #{result.bad_hosts.join(', ')}", result)
        end
        
        return result.success if options[:bool]
        return result
      end

      # raise CommandError if unsuccessful
      def run_command!(cmd, options={}, &block)
        run_command!(cmd, options.merge(:raise=>true), &block)
      end

            
      ########################################################################
      # Keep track of which hosts software is installed on
      # This is to avoid repeating remote commands for dependency checking...
      # The backend is the shared configuration right now...
      # TODO: store/cache this info in the host (ServerDefinition) class
      ########################################################################

      def get_host_software_cache
        fetch(:host_software, {})
      end
      def set_host_software_cache(c)
        set(:host_software, c)
      end

      def add_host_software_cache(host, is_installed=true)
        #logger.debug("cache add: #{host} - #{self}")
        c = get_host_software_cache()
        c[host.to_s] ||= {}
        c[host.to_s][self.name.to_s] ||= {}        
        c[host.to_s][self.name.to_s][self.version.to_s] = is_installed
        set_host_software_cache(c)
        return c
      end

      def delete_host_software_cache(host)
        #logger.debug("cache delete: #{host} - #{self}")
        c = get_host_software_cache()
        c[host.to_s][self.name.to_s].delete(self.version.to_s) rescue nil
        set_host_software_cache(c)
      end
              
      # nil means not in cache, go get it
      def installed_in_cache?(host)
        c = get_host_software_cache
        if !self.version
          return !c[host.to_s][self.name.to_s].empty? rescue nil
        else
          return c[host.to_s][self.name.to_s][self.version.to_s] rescue nil
        end
      end
      
      # These colorize methods don't belong in this class... 
      # and can be replaced with global UI methods and Highline constants
      def colorize(text, color_code)
        "\e[#{color_code}m#{text}\e[0m"
      end
      def red(text); colorize(text, 31); end
      def green(text); colorize(text, 32); end
      def magenta(text); colorize(text, 35); end
      
    end # ::Base

  end
end
