require 'benchmark'
require 'capistrano/cli'

# =========================================================================
# These are helper methods that will be available to your recipes.
# =========================================================================

# say something useful or clever
def say(msg)
  Capistrano::CLI.ui.say(msg)
end

# prompt the user for input
def ask(*args, &block)
  Capistrano::CLI.ui.ask(*args, &block)
end

# sets a variable unless it is already set
def _cset(name, *args, &block)
  unless exists?(name)
    set(name, *args, &block)
  end
end

# Temporarily sets an environment variable, yields to a block, and restores
# the value when it is done.
def with_env(name, value)
  saved, ENV[name] = ENV[name], value.to_s
  yield
ensure
  ENV[name] = saved
end

def check_for_host_absence!
  !find_servers.empty? or raise StandardError.new("No hosts found for ROLES=[#{ENV['ROLES']}], HOSTS=[#{ENV['HOSTS']}]")
end
# execute the block for certrain roles only
def with_roles(*args, &block)
  roles = args.flatten.collect {|i| i.to_s.strip}.reject {|i| i.nil? || i==""}
  raise ArgumentError.new("with_roles() requires atleast one role") if roles.empty?
  with_env("ROLES", roles.join(",")) do
    check_for_host_absence!
    yield
  end
end
alias :with_role :with_roles

# execute the block for certain hosts hosts only
def with_hosts(*args, &block)
  hosts = args.flatten.collect {|i| i.to_s.strip}.reject {|i| i.nil? || i==""}
  raise ArgumentError.new("with_hosts() requires atleast one host") if hosts.empty?
  with_env("HOSTS", hosts.join(",")) do
    check_for_host_absence!
    yield
  end
end
alias :with_host :with_hosts

# execute the block for each host sequentially
# The block will be scoped for that host only.
# The host is yielded to the block for convenience.
# By default, this operates on the current task's scoped hosts.
# So you can call it in a variety of other ways:
# with_each_host {|host| ... }
# with_each_host("host1", "host2") {|h| ... }
# with_each_host(:hosts => ["host1", "host2"]) {|h| ... }
# with_each_host(:roles => [:app]) {|h| ... }
def with_each_host(*args, &block)
  options = args.last.is_a?(Hash) ? args.pop : {}
  hosts = args.flatten.collect {|i| i.to_s.strip}.reject {|i| i.nil? || i==""}
  hosts = find_servers(options) if hosts.empty?
  hosts.each do |host|
    with_hosts(host) do
      yield host
    end
  end
end
alias :with_each_server :with_each_host

# logs the command then executes it locally.
# returns the command output as a string
def run_locally(cmd)
  logger.debug "executing locally: #{cmd.inspect}" if logger
  output_on_stdout = nil
  elapsed = Benchmark.realtime do
    output_on_stdout = `#{cmd}`
  end
  if $?.to_i > 0 # $? is command exit code (posix style)
    raise Capistrano::LocalArgumentError, "Command #{cmd} returned status code #{$?}"
  end
  logger.debug "command finished in #{(elapsed * 1000).round}ms" if logger
  output_on_stdout
end


# If a command is given, this will try to execute the given command, as
# described below. Otherwise, it will return a string for use in embedding in
# another command, for executing that command as described below.
#
# If :run_method is :sudo (or :use_sudo is true), this executes the given command
# via +sudo+. Otherwise is uses +run+. If :as is given as a key, it will be
# passed as the user to sudo as, if using sudo. If the :as key is not given,
# it will default to whatever the value of the :admin_runner variable is,
# which (by default) is unset.
#
# THUS, if you want to try to run something via sudo, and what to use the
# root user, you'd just to try_sudo('something'). If you wanted to try_sudo as
# someone else, you'd just do try_sudo('something', :as => "bob"). If you
# always wanted sudo to run as a particular user, you could do 
# set(:admin_runner, "bob").
def try_sudo(*args)
  options = args.last.is_a?(Hash) ? args.pop : {}
  command = args.shift
  raise ArgumentError, "too many arguments" if args.any?

  as = options.fetch(:as, fetch(:admin_runner, nil))
  via = (fetch(:run_method, nil)==:sudo || fetch(:use_sudo, nil)) ? :sudo : :run
  if command
    invoke_command(command, :via => via, :as => as)
  elsif via == :sudo
    sudo(:as => as)
  else
    ""
  end
end

# Same as sudo, but tries sudo with :as set to the value of the :runner
# variable (which defaults to "app").
def try_runner(*args)
  options = args.last.is_a?(Hash) ? args.pop : {}
  args << options.merge(:as => fetch(:runner, "app"))
  try_sudo(*args)
end

# execute block without shell command escaping (the default Capistrano behavior)
def with_shellescape(doit=true)
  saved, Thread.current[:shellescape] = Thread.current[:shellescape], doit
  yield
ensure
  Thread.current[:shellescape] = saved
end

def without_shellescape()
  with_shellescape(false) do
    yield
  end
end

#############################################################
# Capistrano Dependencies methods
# This might be replaced by Sauce::Software
#############################################################

#
# Auxiliary helper method for the `deploy:check' task. Lets you set up your
# own dependencies.
def depend(location, type, *args)
  deps = fetch(:dependencies, {})
  deps[location] ||= {}
  deps[location][type] ||= []
  deps[location][type] << args
  set :dependencies, deps
end


# Validate the given dependencies 
def check_dependencies(dependencies=[])
  # copied from deploy:check...need something  better than this.
  dependencies = strategy.check!

  other = fetch(:dependencies, {})
  other.each do |location, types|
    types.each do |type, calls|
      if type == :gem
        dependencies.send(location).command(fetch(:gem_command, "gem")).or("`gem' command could not be found. Try setting :gem_command")
      end
      
      calls.each do |args|
        dependencies.send(location).send(type, *args)
      end
    end
  end
  
  if dependencies.pass?
    puts "You appear to have all necessary dependencies installed"
  else
    puts "The following dependencies failed. Please check them and try again:"
    dependencies.reject { |d| d.pass? }.each do |d|
      puts "--> #{d.message}"
    end
    abort
  end
  
end
