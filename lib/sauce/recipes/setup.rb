# Capistrano Tasks for setting up Saucified applications
require 'capistrano/cli'
# Utility functions
def _cset(name, *args, &block)
  unless exists?(name)
    set(name, *args, &block)
  end
end
def say(msg)
  Capistrano::CLI.ui.say(msg)
end
def ask(*args, &block)
  Capistrano::CLI.ui.ask(*args, &block)
end

# Setup Tasks

_cset(:sshkey_file) { 
  ask("Enter a (UNIQUE!!) filename for SSH Key: ", String) {|q| q.default = "#{`whoami`.strip}_#{fetch(:application,'')}_sauce_key"; q.validate = /^[\w]{5,}$/}
}


namespace :setup do

  desc "Setup application environment"
  task :default do
    setup.ssh.key.gen
    setup.ssh.key.authorize
    # TODO: maybe automate github Deploy Key addition (?)
  end
  
  
  namespace :ssh do
    namespace :key do

      desc "Generate SSH Key on localhost"
      task :gen do
        sshkey_file = fetch(:sshkey_file)
        filename = File.join(ENV["HOME"], ".ssh", sshkey_file)
        if File.exists?(filename)
          logger.important("#{filename} already exists!")
          #do_overwrite = ask("Overwrite existing #{filename}? (y/n): ", String) {|q| q.in = ["y","n"] }
          #abort("Aborting...") # if do_overwrite.downcase == "n"
        else
          passphrase = ask("Enter passphrase for SSH Key: ") {|q| q.echo = "x" }
          confirm_passphrase = ask("Confirm passphrase for SSH Key: ") {|q| q.echo = "x" }
          abort("Passphrase did not match!") if passphrase != confirm_passphrase
          comment = sshkey_file
          # generate key on localhost
          keygen_cmd = "ssh-keygen -t rsa -f #{filename} -C #{comment}"
          add_cmd = "ssh-add #{filename}"
          # Done on 127.0.0.1 via SSH so we can interactive handle prompts
          cur_user = fetch(:user, nil)
          set(:user, (`whoami`).strip)
          run("#{keygen_cmd} && #{add_cmd}", :hosts => ["127.0.0.1"]) do |ch,stream,text|
            ch[:state] ||= { :channel => ch }
            host = ch[:state][:channel][:host]
            #logger.info "[#{host} :: #{stream}] #{text}"
            reply = case text
                    when /\b(password|passphrase).*:/i then passphrase
                    when /Overwrite/i then "y" #overwrite file
                    else nil
                    end
            ch.send_data("#{reply}\n") if reply
          end
          set(:user, cur_user) # change user back to config value
          say("All Done. You new SSH Key is at #{filename} and has been added to identities for SSH Agent Forwarding.")
        end
      end

      desc "Add ssh key to ~/.ssh/authorized_keys on all hosts in the environment"
      task :authorize do
        sshkey_file = fetch(:sshkey_file)
        filename = File.join(ENV["HOME"], ".ssh", "#{sshkey_file}.pub")
        abort("SSH Public Key file #{filename} was not found! You should run key:gen") if !File.exists?(filename)
        begin
          # scp public key over to hosts
          say("copying public key to hosts")
          dest_filename = "/tmp/#{sshkey_file}"
          upload(filename, dest_filename, :via => :scp)
          say("appending public key to authorized keys")
          authorized_filename = "~/.ssh/authorized_keys"
          cmd = "if [ -f #{authorized_filename} ]; then " +
            "sed -i -e '/[[:space:]]#{sshkey_file}$/d' #{authorized_filename}; fi; " +
            "cat #{dest_filename} >> #{authorized_filename} && chmod 600 #{authorized_filename}"
          run cmd
        rescue Net::SSH::AuthenticationFailed => e
          raise e
        end
        say("cleaning up...")
        run "rm -rf #{dest_filename}"
        say("All Done. #{sshkey_file} has been appended to #{authorized_filename} on all the hosts.")
        say("NOTE: If you are using git, you probably want to add this key as a Deploy Key for your repository. See https://help.github.com/articles/managing-deploy-keys")
      end

    end
  end
end
