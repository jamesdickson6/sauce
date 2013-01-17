require 'sauce'
require 'capistrano/cli/ui'
module Sauce
  # sauce command-line
  class CLI
    include Capistrano::CLI::UI
    LINE_PADDING = 5
    MIN_MAX_LEN  = 30
    HEADER_LEN   = 60
    # task argument format
    TASK_ARG_REGEX = /^([\w]+(-[\w])?\:?)+$/
    # option (switch) argument format
    OPTION_ARG_REGEX = /^-.+/
    # environment variable argument format
    ENV_ARG_REGEX = /^\w+\=.+/
    # name of executing program
    PROG_NAME = File.basename($0)

    def self.execute(args=ARGV)
      self.new(args).execute!
    end

    def initialize(args)
      @args = args
    end

    def usage_str
<<ENDSTR
  Usage: #{PROG_NAME} [opts] [tasks]
   #{PROG_NAME} -T  : List tasks
   #{PROG_NAME} -vT : List ALL tasks, including internal and those missing a description.
   #{PROG_NAME} -e  : Explain a specific task.  Show the entire description
   #{PROG_NAME} -h  : View this message
  All other arguments are tasks to be executed
   #{PROG_NAME} app:env:sometask
  Environment variables can be passed as well like:
   #{PROG_NAME} app:env:sometask VAR1=COOL  SOME_VAR="ANOTHER VALUE"   
ENDSTR
    end

    def execute!
      config = Sauce.serve # load sauce configuration tasks by default
      # Parse arguments
      task_args = []; opt_args = []; env_vars = [];
      @args.each do |arg|
        if arg =~ TASK_ARG_REGEX
          task_args << arg
        elsif arg =~ OPTION_ARG_REGEX
          opt_args << arg
        elsif arg =~ ENV_ARG_REGEX
          k,v = arg.split("=")
          ENV[k] = v.to_s
        else
          puts("\nInvalid argument #{arg}\n\n#{usage_str}\n")
          exit -1
        end
      end

      # ONLY WORKS WITH 1 task right now!
      task_name = task_args.first

      found_cookable = nil
      # IF task matches a cookable, serve it up
      if task_name
        # Passed task matches a cookable? serve it
        # and modify task name to equal what's after the cookable namespace
        task_ns = []
        cookable_ns = task_name.split(":").compact
        while (!found_cookable && !cookable_ns.empty?)
          found_cookable = Sauce[cookable_ns.join(":")]
          task_ns.unshift(cookable_ns.pop) if !found_cookable
        end
        if found_cookable
          puts "Serving #{found_cookable.namespace}" rescue nil
          config = found_cookable.serve
          task_name = task_ns.join(":")
        end
      end

      if opt_args.find {|arg| ["-T","-vT","-vvT"].include?(arg) } # list tasks
        opts = {
          :pattern => task_name, 
          :namespace_prefix => (found_cookable ? found_cookable.namespace : nil),
          :verbose => (opt_args.include?("-vT"))
        }
        task_list(config, opts)
        exit 0
      elsif opt_args.include?("-e") # explain task
        opts = {
          :namespace_prefix => (found_cookable ? found_cookable.namespace : nil)
        }
        explain_task(config, task_name, opts)
      elsif opt_args.include?("-h") || opt_args.include?("--help") # help
        puts usage_str
      else # execute task
        begin
          task_name = "default" if task_name.to_s == ""
          config.trigger(:load)
          config.logger.level = 5
          config.find_and_execute_task(task_name, :before => :start, :after => :finish)
          config.trigger(:exit)
          exit 0
        rescue Exception => e
          handle_error(e)
          exit -1
        end
      end
    end

    # print task list
    # options: (Hash) or String representing :pattern
    #  :namespace_prefix : Prepend this to the task name
    #  :pattern : The task namespace to list
    #  :no_desc : List tasks without a description (-vT)
    #  :internal : List internal tasks (-vvT)
    #  :verbose : alias for :no_desc => true,:internal => true
    def task_list(config, options={}) #:nodoc:
      options = {:pattern => options} if options.is_a?(String)
      options ||= {}
      options[:pattern]
      if options[:verbose]
        options[:internal] = true
        options[:no_desc] = true
      end
      if options[:pattern].is_a?(String)
        tasks = config.task_list(:all).select {|t| t.fully_qualified_name =~ /#{options[:pattern]}/}
      end
      if tasks.nil? || tasks.length == 0
        puts "Pattern '#{options[:pattern]}' not found. Listing all tasks.\n\n" if options[:pattern]
        tasks = config.task_list(:all)
      end

      if tasks.empty?
        puts "There are no tasks available. Please specify a recipe file to load."
      else
        all_tasks_length = tasks.length
        tasks = tasks.reject do |t|
          (t.description.empty? && !options[:internal]) ||
          (t.description =~ /^\[internal\]/ && !options[:no_desc])
        end

        tasks = tasks.sort_by { |task| task.fully_qualified_name }

        longest = tasks.map { |task| 
          LINE_PADDING + (options[:namespace_prefix].to_s.length) + task.fully_qualified_name.length 
        }.max || 0
        max_length = output_columns - longest - LINE_PADDING
        max_length = MIN_MAX_LEN if max_length < MIN_MAX_LEN

        tasks.each do |task|
          #puts "#{PROG_NAME} #{task.fully_qualified_name}"
          display_name = [options[:namespace_prefix], task.fully_qualified_name].compact.join(":")
          puts "#{PROG_NAME} %-#{longest}s # %s" % [display_name, task.brief_description(max_length)]
        end

        if all_tasks_length > tasks.length
          puts
          puts "Some tasks were not listed, either because they have no description,"
          puts "or because they are only used internally by other tasks. To see all"
          puts "tasks, type `#{PROG_NAME} -vT'."
        end
        
        puts
        puts "Extended help may be available for these tasks."
        puts "Type `#{PROG_NAME} -e taskname' to view it."
      end
    end

    def explain_task(config, name, options={}) #:nodoc:
      task = config.find_task(name)
      display_name = [options[:namespace_prefix], name].compact.join(":")
      if task.nil?
        puts "The task `#{display_name}' does not exist."
      else
        puts "-" * HEADER_LEN
        puts "#{File.basename($0)} #{display_name}"
        puts "-" * HEADER_LEN

        if task.description.empty?
          puts "There is no description for this task."
        else
          puts format_text(task.description)
        end

        puts
      end
    end

    def handle_error(error)
      case error
      when Net::SSH::AuthenticationFailed
        abort "authentication failed for `#{error.message}'"
      when Capistrano::Error
        abort(error.message)
      else raise error
      end
    end


    def format_text(text) #:nodoc:
      formatted = ""
      text.each_line do |line|
        indentation = line[/^\s+/] || ""
        indentation_size = indentation.split(//).inject(0) { |c,s| c + (s[0] == ?\t ? 8 : 1) }
        line_length = output_columns - indentation_size
        line_length = MIN_MAX_LEN if line_length < MIN_MAX_LEN
        lines = line.strip.gsub(/(.{1,#{line_length}})(?:\s+|\Z)/, "\\1\n").split(/\n/)
        if lines.empty?
          formatted << "\n"
        else
          formatted << lines.map { |l| "#{indentation}#{l}\n" }.join
        end
      end
      formatted
    end

    def output_columns #:nodoc:
      if ( @output_columns.nil? )
        if ( self.class.ui.output_cols.nil? || self.class.ui.output_cols > 80 )
          @output_columns = 80
        else
          @output_columns = self.class.ui.output_cols
        end
      end
      @output_columns
    end
  end

end
