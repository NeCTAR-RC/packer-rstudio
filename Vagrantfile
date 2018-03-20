Vagrant.configure("2") do |config|

  # Ubuntu 16.04 (xenial)
  config.vm.define "ubuntu1604" do |c|
    c.vm.box = "ubuntu/xenial64"
    config.vm.provider "libvirt" do |v, override|
      override.vm.box = "rboyer/ubuntu-xenial64-libvirt"
    end
    c.vm.provision "ansible" do |ansible|
      ansible.extra_vars = { nectar_test_build: true,
                             ansible_python_interpreter: "/usr/bin/python3" }
      ansible.playbook = "ansible/playbook-vagrant.yml"
      ansible.become = true
    end
  end

  config.vm.synced_folder ".", "/vagrant", disabled: true

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
