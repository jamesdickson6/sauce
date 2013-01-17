# Standard tasks for a cooked Sauce::Configuration 
# Provides inspection of the saucified applications and their environments
require 'sauce'

task :default do
  list
end

desc "View all saucified applications and environments"
task :list do
  num_apps = Sauce.applications.length
  if num_apps == 0
    logger.important "Found 0 applications with sauce...  Try saucify..."
  else
    logger.info "Found #{num_apps} application#{num_apps==1 ? '':'s'} with sauce!"
    Sauce.applications.each do |app|
      top.send(app.name).send(:view)
    end
  end
end

Sauce.applications.each do |app|
  namespace app.name do

    desc "View all #{app.name} environments details"
    task :default do
      view
    end
    task :view do
      envs = app.environments.each do |env|
        top.send(app.name).send(env.name).send(:view)
      end
    end

    app.environments.each do |env|
      desc "View #{app.name} #{env.name} environment details"
      namespace env.name do
        task :default do
          view
        end
        task :view do
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
        end

      end

    end # end namespace env.name

  end # end namespace app.name

end # end each app

