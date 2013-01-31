require 'sauce/software/base'
require 'sauce/software/package_manager'
module Sauce
  module Software
    # Rubygems is a Package Manager for installing Gems
    class Rubygems < Software::Base
      @software_name = "rubygems"
      @software_command = "gem"
      
      depends_on "ruby"

      include PackageManager

      def install_package(software, version=nil)
        software, version = parse_software_args(software, version)
        run_command("#{command} install #{software} #{version ? '-v '+version.to_s : ''}")
      end

      def uninstall_package(software, version=nil)
        software, version = parse_software_args(software, version)
        run_command("#{command} uninstall #{software} #{version ? '-v '+version.to_s : ''}")        
      end
      
      def package_installed?(software ,version=nil)
        software, version = parse_software_args(software, version)
        output_per_server = {}

        run_command("#{command} list #{software}") do |ch,stream,out|
          warn "#{ch[:server]}: #{out}" if stream == :err
          if out && out.strip != ''
            output_per_server[ch[:server]] ||= ''
            output_per_server[ch[:server]] += out
          end
        end
        
        output_per_server.each do |server, out|
          is_installed = false
          str = out.split("\n").find {|i| i =~ /^#{software}\s+/}
          if str
            is_installed = true
            str = str.sub(/^#{software}\s+/,'').gsub(/\(|\)/,'')
            pkg_versions = str.split(",").collect {|i| i.strip}
            if version
              found_version = pkg_versions.find {|i| i.match(/^#{version}/)}
              if !found_version
                is_installed = false
              end
            end
          end
          if is_installed
            logger.info "#{server}: #{software} #{version} is installed"
          else
            logger.info "#{server}: #{software} #{version} IS NOT installed!"
          end
        end
        
      end
            
    end
  end
end