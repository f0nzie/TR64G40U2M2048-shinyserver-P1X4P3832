# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

$script = <<SCRIPT
echo Loading Puppet modules
puppet module install maestrodev-wget --force --modulepath /usr/share/puppet/modules
SCRIPT

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    # Set up the box
    config.vm.box = "ubuntu/trusty64"
    config.vm.provider "virtualbox" do |v|
      v.memory = 2048
      v.cpus = 2
      v.name = 'TR64G40U2M2048-shinyserver-P1X4P3832'
    end
    
    # Port forwarding
    config.vm.network "forwarded_port", guest: 3838,  host: 3832      # shinyserver
    config.vm.network "forwarded_port", guest: 8787,  host: 8772      # rstudioserver
    config.vm.network "forwarded_port", guest: 80,    host: 8082      # OpenCPU
    config.vm.network "forwarded_port", guest: 10000, host: 10002     # webmin
	
    # synced folders
    config.vm.synced_folder ".", "/vagrant", disabled: false  # need few files from here in the VM
    config.vm.synced_folder  "etc/rstudio", "/etc/rstudio", create:true
    config.vm.synced_folder  "etc/shiny-server", "/etc/shiny-server", create:true
    config.vm.synced_folder  "shiny-server", "/srv/shiny-server", create:true
    # add dummy to avoid "Could not retrieve fact fqdn"
    config.vm.hostname = "vagrant.example.com"

   # Provisioning
   config.vm.provision "shell", inline: $script

    config.vm.provision :puppet,
#    :options => ["--verbose", "--debug"] do |puppet|
#    :options => ["--debug"] do |puppet|
     :options => [] do |puppet|
        puppet.manifests_path = "puppet/manifests"
        puppet.manifest_file = "rstudio-shiny-server.pp"
#        puppet.module_path = "puppet/modules"

    end

end
