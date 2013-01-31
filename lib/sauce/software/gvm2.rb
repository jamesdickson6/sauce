require 'sauce/software/base'
require 'sauce/software/package_manager'
module Sauce
  module Software
    # gvm2 is just a wrapper for gvm.  http://gvmtool.net
    # Version Manager for Groovy,Grails,Gradle
    # gvm operates as a shell function, so we need to load it before we do anything else
    # This makes 'gvm use' worthless with Sauce since it will be calling gvm-init.sh all the time.
    # 'gvm default' can be used instead which makes the change apply to all new shells
    #
    # WARNING: Don't use gvm if you are exporting PATH=GROOVY_HOME:GRAILS_HOME 
    # for other non-saucified groovy/grails applications on your servers.
    class Gvm2 < Software::Base
      @software_name = "gvm2"
      @software_command = "$HOME/bin/gvm2"
      
      include PackageManager

      # no package manager, installed via curl
      def package_manager
        false
      end
      
#      def check_command
#        "which $HOME/.gvm/bin/gvm-init.sh"
#      end

      # install this software
      # this installs gvm via curl and then creates the executable ~/bin/gvm2
      def run_install(options={})
        run_command("curl -s get.gvmtool.net | bash", options)
        fn = command
        # create gvm2 executable to wrap gvm shell command
        cmd = "if [ ! -s #{fn} ]; then mkdir -p $HOME/bin; echo -e '#!/usr/bin/env bash\n. type gvm &> /dev/null || source $HOME/.gvm/bin/gvm-init.sh || exit 1\ngvm $@' >> #{fn}; chmod +x #{fn}; fi;"
        options[:shellescape] = false
        run_command(cmd, options)
      end

      # install package      
      def install_package(options={}, &block)
        software, version = parse_software_args((options[:software]||options[:package]), options[:version])
        options[:quiet] = true # mute tons of output that gvm spits out
        success = false
        run_command("#{command} install #{software} #{version}", options) do |ch,stream,out,result|
          if out.include?("is already installed")
            result.success = true
          end
          if out && out.include?("set as default? (Y/n):")
            ans = ask(out, String) {|q| q.in = ["Y","n"] }
            # ans = "n"
            ch.send_data("#{ans}\n")
            result.success = true
          end
          if out.include?("Done installing!")
            logger.info(out.to_s)
            result.success = true
          end
          # yield ch,stream,out if block_given?
        end
      end

      def uninstall_package(options={}, &block)
        software, version = parse_software_args((options[:software]||options[:package]), options[:version])        
        run_command("#{command} uninstall #{software} #{version}", options, &block)
      end

      def check_package(options={}, &block)
        software, version = parse_software_args((options[:software]||options[:package]), options[:version])
        cmd = "#{command} list #{software} | grep '\* #{version}'"
        options[:shellescape] = false
        run_command(cmd, options, &block)
      end

      # change default groovy,grails,etc
      def default(options={}, &block)
        software, version = parse_software_args((options[:software]||options[:package]), options[:version])
        run_command("#{command} default #{software} #{version}", options)
      end
      
      # change current groovy,grails,etc
      # This is only for the length of the terminal session, and not very useful for Sauce.  
      # You probably want to use #default instead!
      def use(options={}, &block)
        software, version = parse_software_args((options[:software]||options[:package]), options[:version])
        run_command("#{command} use #{software} #{version}", options, &block)
      end

      # print current version(s) in use
      def print_current(options={})
        software, version = parse_software_args((options[:software]||options[:package]), options[:version])
        options[:echo] = true #print output
        run_command("#{command} current #{software}", options, &block)
      end

      # list installed versions of groovy,grails,etc
      # call this with no :software option to list all
      def list_installed(options={})
        software, version = parse_software_args((options[:software]||options[:package]||""), options[:version])
        run_command("#{command} list #{software} | grep \"*\"", options)
      end

      def selfupdate(options={}, &block)
        run_command("#{command} selfupdate", options, &block)
      end
      
      
      
    end
  end
end
