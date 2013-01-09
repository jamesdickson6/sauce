require 'sauce'
# Capistrano tasks for a Sauce configuration

desc "View details about the #{Sauce.applications.length} saucified applications"
task "list-apps" do
  puts "Found #{Sauce.applications.length} saucified application#{Sauce.applications.length==1 ? '':'s'}"
  Sauce.applications.each do |app|
    top.send(app.name).send(:view)
    puts "\n"
  end
end

Sauce.applications.each do |app|

  namespace app.name do

    desc "View details about #{app.name} environments"
    task "view" do
      envs = app.environments
      puts ' '*2+"#{app.name} has #{envs.length} environments defined:"
      envs.each do |env| 
        top.send(app.name).send(env.name).send(:view)
      end
    end

    app.environments.each do |env|
      namespace env.name do
        desc "View details about the #{app.name} #{env.name} environment"
        task "view" do
          servers = env.capistrano_config.find_servers
          puts ' '*4+"#{env.name} (#{servers.length} server#{servers.length==1 ? '':'s'})"
          servers.each do |s| 
            puts ' '*6+"#{s.host}#{s.port ? ':'+s.port : ''} #{s.options.empty? ? '' : '  options: '+s.options.inspect}"
          end
        end

      end
    end

  end

end
