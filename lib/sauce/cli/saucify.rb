require 'sauce'
module Sauce
  module CLI
    # Create appname.sauce file in current directory, no fancy cli options needed right now. 
    # Just use first ARG
    class Saucify
      TEMPLATE_DIR = File.expand_path(File.join(File.dirname(__FILE__),"../../../examples"))
      DEFAULT_TEMPLATE = "default"
      TEMPLATE_APP_NAME = "yourCoolApp"
      APPNAME_REGEX = /^[A-Z0-9_]+$/i

      def self.execute(opts={})
        appname = opts[:name] || ARGV[0]
        abort("  Usage: #{File.basename($0)} <appname>\n") if appname.nil?
        abort("  #{appname} is an invalid application name!\n\n") unless appname =~ APPNAME_REGEX
        dir = opts[:dir] || Dir.pwd
        template = opts[:template] || "default"
        template_fn = File.join(TEMPLATE_DIR, "#{template}#{Sauce::SAUCE_FILE_EXTENSION}")
        abort("  Template #{template_fn} does not exist!\n") unless File.exists?(template_fn)
        sauce_text = File.read(template_fn).gsub(TEMPLATE_APP_NAME, appname)
        sauce_fn = File.join(dir, "#{appname}#{Sauce::SAUCE_FILE_EXTENSION}")
        abort("  #{sauce_fn} already exists!\n") if File.exists?(sauce_fn)
        File.open(sauce_fn, "w") {|f| f.write(sauce_text) }
        puts("  Successfully created #{sauce_fn}\n")
        puts("  Now get brewing!\n")
      end
    end
  end
end
