# -*- mode: ruby -*-
# vi: set ft=ruby :

# this is set high to give some flexiblity.
# ideally this should be passed from an environment var
NODE_COUNT = 10

Vagrant.configure(2) do |config|
  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
  end

  config.vm.define :a2 do |a2|
    a2.vm.box = "bento/ubuntu-16.04"
    a2.vm.synced_folder ".", "/opt/a2-testing", create: true
    a2.vm.hostname = 'automate-deployment.test'
    a2.vm.network 'private_network', ip: '192.168.33.199'
    a2.vm.boot_timeout = 600
    a2.vm.provision "shell", inline: "apt-get update && apt-get install -y unzip"
    a2.vm.provision "shell", inline: "sysctl -w vm.max_map_count=262144"
    a2.vm.provision "shell", inline: "sysctl -w vm.dirty_expire_centisecs=20000"
    a2.vm.provision "shell", inline: "echo 192.168.33.199 automate-deployment.test | sudo tee -a /etc/hosts"
    a2.vm.provision "shell", inline: "cd /home/vagrant && curl https://packages.chef.io/files/current/automate/latest/chef-automate_linux_amd64.zip |gunzip - > chef-automate && chmod +x chef-automate"
    a2.vm.provision "shell", inline: "sudo ./chef-automate init-config"
    a2.vm.provision "shell", inline: "sudo ./chef-automate deploy config.toml --skip-preflight"
    a2.vm.provision "shell", inline: "if [ -f /opt/a2-testing/automate.license ]; then sudo ./chef-automate license apply $(< /opt/a2-testing/automate.license) && sudo ./chef-automate license status ; fi"
    a2.vm.provision "shell", inline: "sudo ./chef-automate admin-token > /opt/a2-testing/a2-token"
  end

  config.vm.define :srvr do |srvr|
    srvr.vm.box = "bento/ubuntu-16.04"
    srvr.vm.synced_folder ".", "/opt/a2-testing", create: true
    srvr.vm.hostname = 'chef-server.test'
    srvr.vm.network 'private_network', ip: '192.168.33.200'
    srvr.vm.provision "shell", inline: "echo 192.168.33.199 automate-deployment.test | sudo tee -a /etc/hosts"
    srvr.vm.provision "shell", inline: "echo 192.168.33.200 chef-server.test | sudo tee -a /etc/hosts"
    srvr.vm.provision "shell", inline: "cd /opt/a2-testing && wget -N -nv https://packages.chef.io/files/stable/chef-server/12.17.33/ubuntu/16.04/chef-server-core_12.17.33-1_amd64.deb && sudo dpkg -i /opt/a2-testing/chef-server-core*.deb && chef-server-ctl reconfigure"
    srvr.vm.provision "shell", inline: "mkdir -p /opt/a2-testing/.chef"
    srvr.vm.provision "shell", inline: "if [ \"$(sudo chef-server-ctl user-show | grep 'admin')\" == \"\" ]; then sudo chef-server-ctl user-create admin first last admin@example.com 'adminpwd' --filename /opt/a2-testing/.chef/admin.pem; fi"
    srvr.vm.provision "shell", inline: "if [ \"$(sudo chef-server-ctl org-show | grep 'a2')\" == \"\" ]; then sudo chef-server-ctl org-create a2 'automate2' --association_user admin --filename /opt/a2-testing/.chef/a2-validator.pem; fi"
    srvr.vm.provision "shell", inline: "sudo chef-server-ctl set-secret data_collector token $(< /opt/a2-testing/a2-token) && sudo chef-server-ctl restart nginx && sudo chef-server-ctl restart opscode-erchef"
    srvr.vm.provision "shell", inline: "echo \"data_collector['root_url'] = 'https://automate-deployment.test/data-collector/v0/'\" | sudo tee -a /etc/opscode/chef-server.rb"
    srvr.vm.provision "shell", inline: "echo \"profiles['root_url'] = 'https://automate-deployment.test'\" | sudo tee -a /etc/opscode/chef-server.rb"
    #srvr.vm.provision "shell", inline: "sudo cat >/etc/opscode/chef-server.rb <<EOL
#data_collector['root_url'] = 'https://automate-deployment.test/data-collector/v0/'
#profiles['root_url'] = 'https://automate-deployment.test'
#EOL"
    srvr.vm.provision "shell", inline: "sudo chef-server-ctl reconfigure"
    srvr.vm.provision "shell", inline: "touch /home/vagrant/srvr-token"
  end

  NODE_COUNT.times do |i|
    node_id = "node1#{i}"
    config.vm.define node_id do |node|
      node.vm.provider "virtualbox" do |vb|
        vb.memory = 512
        vb.cpus = 2
      end
      node.vm.box = "archlinux/archlinux"
      node.vm.hostname = "#{node_id}.test"
      node.vm.synced_folder ".", "/opt/a2-testing", create: true
      node.vm.network :private_network, ip: "192.168.33.1#{i}"
      node.ssh.username = "vagrant"
      node.ssh.password = "vagrant"
      node.vm.provision "shell", inline: "echo 192.168.33.200 chef-server.test | sudo tee -a /etc/hosts"
      node.vm.provision "shell", inline: "echo 192.168.33.1#{i} #{node_id}.test | sudo tee -a /etc/hosts"
      node.vm.provision "shell", inline: "sudo pacman -Sy --noconfirm wget binutils fakeroot cronie"
      node.vm.provision "shell", inline: "sudo -H -u vagrant bash -c 'cd /opt/a2-testing && wget -N -nv https://aur.archlinux.org/cgit/aur.git/snapshot/chef-dk.tar.gz && tar -xvzf *.tar.gz'"
      node.vm.provision "shell", inline: "if [ \"$(ls /opt/a2-testing/chef-dk/chef*xz)\" == \"\" ]; then sudo -H -u vagrant bash -c 'cd /opt/a2-testing/chef-dk && makepkg -s'; fi"
      node.vm.provision "shell", inline: "cd /opt/a2-testing/chef-dk && sudo pacman -U --noconfirm *xz"
      node.vm.provision "shell", inline: "sudo mkdir -p /etc/chef && cat >/etc/chef/client.rb <<EOL
log_level        :info
log_location     STDOUT
chef_server_url  'https://chef-server.test/organizations/a2'
validation_client_name 'a2-validator'
validation_key '/opt/a2-testing/.chef/a2-validator.pem'
client_key '/etc/chef/client.pem'
ssl_verify_mode  :verify_none
EOL"
      node.vm.provision "shell", inline: "sudo /usr/bin/chef-client -r 'recipe[audit::default]'"
      node.vm.provision "shell", inline: "sudo systemctl enable cronie.service && sudo systemctl start cronie.service"
      node.vm.provision "shell", inline: "(crontab -l 2>/dev/null; echo \"*/5 * * * * sudo /usr/bin/chef-client >/dev/null 2>&1\") | crontab -"

    end
  end

end
