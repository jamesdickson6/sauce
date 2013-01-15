require 'sauce'
# Capistrano tasks for a Sauce configuration
# Provides inspection of the saucified applications and their environments

task :default do
  list
end

desc "View all saucified applications and environments"
task :list do
  num_apps = Sauce.applications.length
  if num_apps == 0
    logger.info "Found 0 applications with sauce...  Check out saucify..."
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
          logger.info ' '*4+"#{env.name} (#{servers.length} server#{servers.length==1 ? '':'s'})"
          servers.each do |s| 
            logger.info ' '*6+"#{s.host}#{s.port ? ':'+s.port : ''} #{s.options.empty? ? '' : '  options: '+s.options.inspect}"
          end
        end

      end

    end # end namespace env.name

  end # end namespace app.name

end # end each app

