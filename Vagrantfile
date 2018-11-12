Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.network "public_network"
  config.vm.provision :shell, path: "centos/centos-jenkins-provision.sh", :args =>"-update -fw -skipwiz"
end
