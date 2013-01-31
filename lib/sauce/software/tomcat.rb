require 'sauce/software/base'
require 'sauce/software/service'
module Sauce
  module Software
    # Tomcat Server.  This is a container for other web applications
    class Tomcat < Software::Base
      @software_name = "tomcat"
      @software_command = "tomcat7" # not used
      @software_version = "7.0.35"
      @port = "8080"
      @manager_port = "8005"
      @required_options = {
        :catalina_base => "This is your CATALINA_BASE directory",
        :version => "Default is #{@sofwtare_version}"
      }.freeze

      depends_on "java"
      
      attr_accessor :catalina_base 
      attr_accessor :port, :manager_port, :ajp_port
      
      include Service
      
      def package_manager
        false
      end
      def service_manager
        false
      end
      
      def check_command
        "[ -d #{catalina_base}/bin ]"
      end
      
      # install tomcat instance
      def run_install(options={}, &block)
        options = options.merge(:shellescape=>false, :echo_err => true)
        # fetch tomcat and extract it to basedir
        rtn = run_command("mkdir -p #{catalina_base}", options)
        ver = options[:version] || self.version
        fn = "apache-tomcat-#{ver}"
        tgz_url = "http://mirrors.gigenet.com/apache/tomcat/tomcat-#{ver[0].chr}/v#{ver}/bin/#{fn}.tar.gz"
        fetch_cmd = "[ -f /tmp/#{fn}.tar.gz ] || (cd /tmp && wget #{tgz_url});"
        fetch_cmd << " [ -d /tmp/#{fn} ] || (cd /tmp && tar -xzf #{fn}.tar.gz);"
        rtn = run_command(fetch_cmd, options) if rtn.success?
        # copy to catalina_base, but don't overwrite if it already exists..
        rtn = run_command("[ -f #{catalina_base}/bin ] || cp -R /tmp/#{fn}/* #{catalina_base}/", options) if rtn.success?
        
        # swap in port values, only overwrite the default values!
        run_command("sed -i -e 's/Server port=\"8005\"/Server port=\"#{manager_port}\"/g' #{catalina_base}/conf/server.xml", options) if manager_port
        run_command("sed -i -e 's/Connector port=\"8080\"/Connector port=\"#{port}\"/g' #{catalina_base}/conf/server.xml", options) if port
        run_command("sed -i -e 's/Connector port=\"8009\"/Connector port=\"#{ajp_port}\"/g' #{catalina_base}/conf/server.xml", options) if ajp_port        
        return rtn
      end

      # TODO: 
      def running?(options={}, &block); 
        raise NotImplementedError.new("running?() is not implemented by #{self.class.name}")
      end
      
      def start(options={}, &block)
        run_command("cd #{catalina_base}/bin && ./startup.sh #{start_options}", options)
      end
      
      def stop(options={}, &block)
        run_command("cd #{catalina_base}/bin && ./shutdown.sh", options)
      end

      def restart(options={})
        run_command("cd #{catalina_base}/bin; ./shutdown.sh; sleep 2; ./startup.sh #{start_options}", options)
      end

    end
  end
end
