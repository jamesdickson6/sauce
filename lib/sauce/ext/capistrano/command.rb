module Capistrano
  class Command
    class Tree
      class Branch
        # allow disabling of command escaping!. Default is ON.
        def initialize(command, options, callback)
          if Thread.current[:shellescape] == false
            @command = command.strip
          else
            @command = command.strip.gsub(/\r?\n/, "\\\n")
          end
          @callback = callback || Capistrano::Configuration.default_io_proc
          @options = options
          @skip = false
        end
      end
    end
  end
end