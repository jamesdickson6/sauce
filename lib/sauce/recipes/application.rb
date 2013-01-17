# Default Tasks for a Sauce::Application::Environment

desc "List all application environments"
task :default do
  list_environments
end

desc "[internal] List all application environments"
task :list_environments do
  appname = fetch(:application)
  app = Sauce[appname]
  abort("Sauce application '#{appname}' does not exist!") if !app

  logger.info("#{appname} has #{app.environments.length} environments:\n")
  app.environments.each do |env|
    servers = env.cap_config.find_servers
    # Capistrano doesnt provide ServerDefinition.new.roles, weak.
    host_roles = {}
    env.cap_config.roles.each {|role_name, role|
      role.servers.each {|s| 
        host_roles["#{s.host}:#{s.port}"] ||= []; 
        host_roles["#{s.host}:#{s.port}"] << role_name
      }
    }
    logger.info "#{env.name} (#{servers.length} server#{servers.length==1 ? '':'s'})"
    servers.each do |s|
      roles_str = (host_roles["#{s.host}:#{s.port}"] || []).join(", ")
      logger.info "#{s.host}#{s.port ? ':'+s.port.to_s : ''}  [#{roles_str}]  #{s.options.empty? ? '' : s.options.inspect}"
    end
    logger.info("\n")
  end
end
