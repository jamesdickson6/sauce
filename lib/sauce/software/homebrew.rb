require 'sauce/software/base'
require 'sauce/software/package_manager'
module Sauce
  module Software
    # Package Manager for OSX
    class Homebrew < Software::Base
      @software_name = "homebrew"
      @software_command = "brew"      

      depends_on "ruby"
      depends_on "rubygems"
      
      include PackageManager

      PACKAGE_NAME_MAP = {
        "mysqld" => "mysql"
      }

      # don't install homebrew with other software
      def package_manager
        @false
      end
      
      # install homebrew
      def run_install(options={})
        cmd = "ruby -e \"$(curl -fsSkL raw.github.com/mxcl/homebrew/go)\""
        rtn = run_command(cmd, options) do |ch,stream,out|
          if out.include?("already installed")
            success = true
          end
          # proceed through prompt
          if out.include?("Press ENTER to continue or any other key to abort")
            ch.send_data("\n")
          end
        end
        return rtn.success # rtn
      end

      def install_package(options={})
        software, version = parse_software_args((options[:software]||options[:package]), options[:version])
        logger.debug("Warning: homebrew cannot install specific versions right now!, installing the latest #{software}") if version
        cmd = "#{command} install #{software}"
        run_command(cmd, options)
      end
      
      def check_package(options={})
        software, version = parse_software_args((options[:software]||options[:package]), options[:version])
        cmd = "#{command} list #{software} | grep \"#{software}/#{version}\""
        options[:shellescape] = false
        run_command(cmd, options)
      end

      # tap a new keg of formulas
      def tap(options={})
        repo = (options[:keg] || options[:repository]) or raise ArgumentError.new("need a :keg or :repository to tap")        
        run_command("#{command} tap #{repo}", options)
      end

      # untap keg of formulas
      def untap(options={})
        repo = (options[:keg] || options[:repository]) or raise ArgumentError.new("need a :keg or :repository to untap")
        run_command("#{command} untap #{repo}", options)
      end

    end
  end
end
