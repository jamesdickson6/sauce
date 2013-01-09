require 'capistrano'
require 'capistrano/cli'
# Sauce's own subclass of Capistrano::CLI
# overrides execute! to inject a app:env tasks, or the default sauce tasks
# also changes help a bit to print 'sauce ' instead of 'cap '
module Sauce
  # The CLI class encapsulates the behavior of capistrano when it is invoked
  # as a command-line utility. This allows other programs to embed Capistrano
  # and preserve its command-line semantics.
  class CLI < Capistrano::CLI

    # could override this.. or not use it as we are now...
    def instantiate_configuration(options={}) #:nodoc:
      Capistrano::Configuration.new(options)
    end

    # overridden...
    def execute!
      Sauce.serve # load sauce tasks by default
      # OR ...Are we loading a specific app:env ?
      first_arg = ARGV.first
      if first_arg and first_arg =~ /\w+:\w+/
        ar = first_arg.split(":")
        appname, envname = ar[0], ar[1]
        if Sauce[appname] && Sauce[appname][envname]
          Sauce[appname][envname].serve
        end
        puts "Served #{appname}:#{envname} !!"
      end
      config = Capistrano::Configuration.instance # this is set via the serve methods above
#      config = instantiate_configuration(options)
      config.debug = options[:debug]
      config.dry_run = options[:dry_run]
      config.preserve_roles = options[:preserve_roles]
      config.logger.level = options[:verbose]

      set_pre_vars(config)
#      load_recipes(config) # no need for this

      config.trigger(:load)
      execute_requested_actions(config)
      config.trigger(:exit)

      config
    rescue Exception => error
      handle_error(error)
    end


    #JD: Copied verbatim from capistrano-2.13.5/lib/cli/help/rb
    # Just changed 'cap ' to '#{File.basename($0)} ' to avoid confusion
      def task_list(config, pattern = true) #:nodoc:
        tool_output = options[:tool]

        if pattern.is_a?(String)
          tasks = config.task_list(:all).select {|t| t.fully_qualified_name =~ /#{pattern}/}
        end
        if tasks.nil? || tasks.length == 0
          warn "Pattern '#{pattern}' not found. Listing all tasks.\n\n" if !tool_output && !pattern.is_a?(TrueClass)
          tasks = config.task_list(:all)
        end

        if tasks.empty?
          warn "There are no tasks available. Please specify a recipe file to load." unless tool_output
        else
          all_tasks_length = tasks.length
          if options[:verbose].to_i < 1
            tasks = tasks.reject { |t| t.description.empty? || t.description =~ /^\[internal\]/ }
          end

          tasks = tasks.sort_by { |task| task.fully_qualified_name }

          longest = tasks.map { |task| task.fully_qualified_name.length }.max
          max_length = output_columns - longest - LINE_PADDING
          max_length = MIN_MAX_LEN if max_length < MIN_MAX_LEN

          tasks.each do |task|
            if tool_output
              puts "#{File.basename($0)} #{task.fully_qualified_name}"
            else
              puts "#{File.basename($0)} %-#{longest}s # %s" % [task.fully_qualified_name, task.brief_description(max_length)]
            end
          end

          unless tool_output
            if all_tasks_length > tasks.length
              puts
              puts "Some tasks were not listed, either because they have no description,"
              puts "or because they are only used internally by other tasks. To see all"
              puts "tasks, type `#{File.basename($0)} -vT'."
            end

            puts
            puts "Extended help may be available for these tasks."
            puts "Type `#{File.basename($0)} -e taskname' to view it."
          end
        end
      end

      def explain_task(config, name) #:nodoc:
        task = config.find_task(name)
        if task.nil?
          warn "The task `#{name}' does not exist."
        else
          puts "-" * HEADER_LEN
          puts "#{File.basename($0)} #{name}"
          puts "-" * HEADER_LEN

          if task.description.empty?
            puts "There is no description for this task."
          else
            puts format_text(task.description)
          end

          puts
        end
      end



  end
end
