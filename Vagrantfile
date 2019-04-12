Vagrant.configure("2") do |config|

  # Ubuntu 18.04 (bionic)
  config.vm.define "rstudio" do |c|
    c.vm.box = "ubuntu/bionic64"
    c.vm.provider "libvirt" do |v, override|
      override.vm.box = "generic/ubuntu1804"
    end

    # Fix Weird DNS set in box
    c.vm.provision "shell", inline: "sed -i 's/^DNS=.*/DNS=1.1.1.1/g' /etc/systemd/resolved.conf"
    c.vm.provision "shell", inline: "systemctl restart systemd-resolved"

    c.vm.provision "ansible" do |ansible|
      ansible.compatibility_mode = "2.0"
      ansible.extra_vars = { nectar_test_build: true,
                             ansible_python_interpreter: "/usr/bin/python3" }
      ansible.playbook = "ansible/playbook.yml"
      ansible.become = true
    end

  end

  #config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.network :forwarded_port, guest: 80, host: 8080, host_ip: '0.0.0.0'
  config.vm.network :forwarded_port, guest: 443, host: 8443, host_ip: '0.0.0.0'

  config.vm.provider :virtualbox do |v|
    v.memory = 2048
    v.cpus = 2
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    v.customize ["modifyvm", :id, "--ioapic", "on"]
  end

  config.vm.provider :libvirt do |v|
    v.memory = 2048
    v.cpus = 2
  end

end
