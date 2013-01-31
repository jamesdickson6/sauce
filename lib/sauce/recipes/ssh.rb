# Capistrano Tasks for setting up Saucified applications

_cset(:sshkey_file) { 
  ask("Enter a (UNIQUE!!) filename for your SSH Key: ", String) {|q| q.default = "#{`whoami`.strip}_#{fetch(:application,'')}_sauce_key"; q.validate = /^[\w]{5,}$/}
}

namespace :ssh do
  
  desc "Setup SSH key on all hosts in the environment"
  task :setup_key do
    top.ssh.key.gen
    top.ssh.key.authorize
  end
  
  namespace :key do

    desc "[internal] Generate SSH Key on localhost"
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
        # Done via 127.0.0.1 so we can handle interactive prompts (sucky)
        cur_user = fetch(:user, nil)
        cur_password = fetch(:password, nil)        
        localhost_user = (`whoami`).strip
        localhost_password = ask("#{localhost_user}@localhost Password: ") {|q| q.echo = false }
        set(:user, localhost_user)
        set(:password, localhost_password)
        run("#{keygen_cmd} && #{add_cmd}", :hosts => ["127.0.0.1"]) do |ch,stream,text|
          reply = case text
                  when /\b(password|passphrase).*:/i then passphrase
                  when /Overwrite/i then "y" #overwrite file
                  else nil
                  end
          ch.send_data("#{reply}\n") if reply
        end
        # ssh auth back to config values
        set(:user, cur_user) 
        set(:password, cur_password)
        say("All Done. You new SSH Key is at #{filename} and has been added to identities for SSH Agent Forwarding.")
      end
    end

    desc "[internal] Add ssh key to ~/.ssh/authorized_keys on all hosts in the environment"
    task :authorize do
      #ssh_options[:forward_agent] = false
        _cset(:password) { ask("Password: ") {|q| q.echo = false } }
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
      ssh_options[:forward_agent] = true
    end

  end
end
