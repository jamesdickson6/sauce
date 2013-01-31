require 'sauce/software'
module Sauce
  module Software
    # Mixin for software that runs as a service/daemon
    # Redefine the run_stop|start|restart|reload|status, and/or rely on a service_manager
    # You could also redefine start|stop|restart|reload|status if you never want to use a service_manager
    # +service_manager+: set this if you are using another software to manage this service. Default comes from configuration.
    # +service_name+: This can be set if you are using a service_manager. Default is (software) name     
    # These are common attributes, you can define others for your service, and use these however necessary.    
    # +config_file+: 
    # +pid_file+: Location of pid file, this is used by the default stop task if it is set.
    # +log_file+: Location of log file
    # +start_options+: extra arguments/switches to be appended to the start commans.
    #
    # If +pid_file+ is set, #stop will take action, attempting to to stop the service via a KILL <pid>
    module Service
      attr_accessor :service_manager, :service_name
      attr_accessor :config_file, :pid_file, :log_file, :start_options
      
      # service_manager is optional, software can know how start and stop itself..
      # override this in your subclass or rely on configuration by default
      # it should return an instance of Software::ServiceManager or false to indicate No Service Manager
      def service_manager
        (!@service_manager.nil? ? @service_manager : (fetch("#{name}_service_manager", nil) || fetch(:default_service_manager, nil)))
      end
      def service_manager=(software)
        raise ArgumentError.new("Expected a ServiceManager and got a (#{service_manager.class}) #{service_manager} instead.") unless software==false || software.is_a?(ServiceManager)
        raise ArgumentError.new("#{name} set service_manager=(itself) #{self.class}") if software.class == self.class        
        @service_manager = software
      end

      # send an arbitrary signal, default is TERM
      def kill(options={}, &block)
        raise NotImplementedError.new("cannot send a signal to #{self} without setting pid_file") unless pid_file
        sig = options[:signal] || options[:sig] || "TERM"
        run_command("pid=$(cat #{pid_file}) && kill -#{sig} $pid")
      end

      def start_command
        "#{command} #{start_options}"
      end

      def start(options={}, &block)
        return self.service_manager.start(options.merge(:software => self), &block) if !self.service_manager.nil?
        run_start(options, &block)
      end

      def run_start(options={}, &block)
        #raise NotImplementedError.new("start(options={}) is not implemented by #{self.class.name}")
        run_command(start_command, options, &block)
      end

      def stop(options={}, &block)
        return self.service_manager.stop(options.merge(:software => self), &block) if !self.service_manager.nil?
        run_stop(options, &block)
      end
      def run_stop(options={}, &block)
        kill(options, &block)
      end

      def reload(options={}, &block)
        return self.service_manager.reload(options.merge(:software => self), &block) if !self.service_manager.nil?
        run_reload(options, &block)
      end
      def run_reload(options={}, &block)
        kill(options.merge(:signal=>"USR1"), &block)
      end
                  
      def restart(options={}, &block)
        return self.service_manager.restart(options.merge(:software => self), &block) if !self.service_manager.nil?
        run_restart(options, &block)
      end
      # this is a rolling restart...
      # you can override this to execute in parallel if you want/need
      def run_restart(options={}, &block)
        with_each_host { stop(options); start(options) }
      end
      
      def status(options={}, &block)
        return self.service_manager.status(options.merge(:software => self), &block) if !self.service_manager.nil?
        run_status(options, &block)
      end
      alias :running? :status
      
      def run_status(options={}, &block)
        raise NotImplementedError.new("cannot check process status for #{self} without setting pid_file") unless pid_file
        run_command("pid=$(cat #{pid_file} && ps -p $pid &> /dev/null")
      end
  
    end
  end
end
