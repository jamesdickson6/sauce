require 'sauce/software/base'
require 'sauce/software/tomcat'
module Sauce
  module Software
    # Solr Server within it's own Tomcat instance
    #
    class SolrTomcat < Tomcat
      @software_name = "solr"
      @software_command = "solr"
      @software_version = "4.1.0"
      @port = "8983"
      @manager_port = "8006"
      @required_options = self.superclass.required_options.merge({
        :install_dir => "Where to install solr. Your solr.war and data will live here. Eg. /opt/solr"
      }).freeze #inherit/extend required options

      attr_accessor :install_dir, :tomcat_version

      include Service
      
      def check_command
        "[ -f #{install_dir}/solr.war ]  && [ -f #{catalina_base}/conf/Catalina/localhost/solr.xml ]"
      end

      # install tomcat with solr
      def run_install(options={}, &block)
        options = options.merge(:shellescape=>false)
        # install tomcat
        tomcat_ver = self.tomcat_version || Tomcat.software_version
        rtn = super(options.merge(:version => tomcat_ver), &block)
        return rtn unless rtn.success?
        
        # fetch solr
        ver = options[:version] || self.version
        fn = "solr-#{ver}"
        tgz_url = "http://www.globalish.com/am/lucene/solr/#{ver}/#{fn}.tgz"
        fetch_cmd = "[ -f /tmp/#{fn}.tgz ] || (cd /tmp && wget #{tgz_url});"
        fetch_cmd << " [ -d /tmp/#{fn} ] || (cd /tmp && tar -xzf #{fn}.tgz);"
        logger.important("This may take a while, the file is large...")
        rtn = run_command(fetch_cmd, options) if rtn.success?
        return rtn unless rtn.success?

        # create install_dir if needed
        rtn = run_command("mkdir -p #{install_dir}", options)
                
        # copy example/solr to install_dir, don't overwrite!
        rtn = run_command("[ -f #{install_dir}/solr.war ] || cp -R /tmp/#{fn}/example/solr/* #{install_dir}/", options) if rtn.success?
        # copy solr.war to install_dir
        rtn = run_command("[ -f #{install_dir}/solr.war ] || cp /tmp/#{fn}/example/webapps/solr.war #{install_dir}/solr.war", options) if rtn.success?
        return rtn unless rtn.success?
        
        # install solr within tomcat, done simply by
        # generating solr.xml and copying it into place
        xml = <<-ENDSTR
<?xml version="1.0" encoding="utf-8"?>
<Context docBase="#{install_dir}/solr.war" debug="0" crossContext="true">
  <Environment name="solr/home" type="java.lang.String" value="#{install_dir.chomp('/')}/" override="true"/>
</Context>
ENDSTR
        tmp_fn = "/tmp/solr.xml"
        File.delete(tmp_fn) if File.exists?(tmp_fn)
        File.open(tmp_fn, "w") {|f| f.write(xml) }
        #engine_name ||= "Catalina"
        #hostname ||= "localhost"
        dest_fn = "#{catalina_base}/conf/Catalina/localhost/solr.xml"
        logger.info("Generating #{tmp_fn} and copying it to #{dest_fn}")
        rtn = run_command("mkdir -p #{File.dirname(dest_fn)}", options)
        #NOTE: can't use ~ or $HOME with upload/scp destinations...
        #  workaround is to copy, then mv
        upload(tmp_fn, tmp_fn, options.merge(:via => :scp)) if rtn.success?
        rtn = run_command("[ -f #{dest_fn} ] || mv #{tmp_fn} #{dest_fn}", options)
        
        return rtn
      end
      
      
    end
  end
end
