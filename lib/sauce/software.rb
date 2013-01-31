require 'sauce/software/base'
require 'sauce/ext/capistrano/command' # prevent command escaping
module Sauce
  module Software

    # Generic software error
    class Error < StandardError
    end

    # Error executing remote command, contains CommandResult object
    class CommandError < Error
      attr_accessor :result
      def initialize(msg, result=nil)
        super(msg)
        @result=result
      end
    end
         
    # find Software::<Class> via a string (filename)
    # Eg. find_class("ruby") would return a Software::Ruby (a Class)
    #     find_class("some/service", conf) would return Software::Some::Service (a Class)
    def self.find_class(software)
      software_file = "sauce/software/#{software}"
      require(software_file)
      klass_str = software.to_s.split("/").reject{|i| i==""}.collect {|i| i.capitalize.gsub(/_(.)/) {$1.upcase} }.join("::")
      if const_defined?(klass_str)
        klass = const_get(klass_str)
        raise Error, "#{klass.name} is not a type of Software!" unless klass < Software::Base
        return klass
      end
      raise Error, "could not find `#{self.name}::#{klass_str}' in `#{software_file}'"
    rescue LoadError
      raise Error, "could not find any software named `#{software}'"
    end

    # Returns instance of Software::<Class> via a string|symbol... 
    # version can be passed in place of options Hash
    # Examples of calls from within a Configuration:
    #  yum = Software.new("yum", self)
    #  groovy = Software.new("groovy", self, "2.0.4")    
    #  nxginx = Software.new("mginx", self, :command => "/sbin/nginx")
    #  mysqldump = Software.new("/mysql/mysqldump", self)
    def self.new(software_name, configuration, opts={})
      opts = {:version => opts} if opts.is_a?(String) # allow version to be passed in place of opts
      find_class(software_name).new(configuration, opts)
    end
    
  end
end
