#!/usr/bin/env bash


# If provisioned on a Vagrant box, eth0 will always be for a NAT address so your Jenkins address will be on eth1.
#   https://superuser.com/questions/752954/need-to-do-bridged-adapter-only-in-vagrant-no-nat

# Check if Jenkins is installed and exit if it does
#[ "$(yum list installed jenkins | grep jenkins)" ] && echo "Jenkins already installed." && exit || echo "Jenkins not installed. Installing now..."

# command line arguments
while [ $# -gt 0 ]
do
    case "$1" in
        -update) update=on;;
        -fw)  fw=on;;
        -skipwiz)  skipwiz=on;;
        esac
        shift
done

# Optional only enable this if you want your machine updated
[ $update ] && sudo yum update -y

# Install java 1.8
sudo yum install java-1.8.0-openjdk-devel -y

# Install Jenkins
curl --silent --location http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo | sudo tee /etc/yum.repos.d/jenkins.repo
sudo rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
sudo yum install jenkins -y

# Set Jenkins to serve requests on port 8000
sudo sed -i 's/JENKINS_PORT="8080"/JENKINS_PORT="8000"/g' /etc/sysconfig/jenkins

# INSECURE Skip setup wizard
if [ $skipwiz ]
then
    sudo sed -i 's/JENKINS_JAVA_OPTIONS="-Djava.awt.headless=true"/JENKINS_JAVA_OPTIONS="-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"/g' /etc/sysconfig/jenkins
fi

# Start Jenkins and enable boot
# Works in Centos 7 and 6
sudo service jenkins start
sudo chkconfig jenkins on


# Adjust firewall for access on port 8000
if [ $fw ]
then
    if [ "$(cat /etc/centos-release | grep 7.)" ]
    then
        [ "$(sudo service firewalld status | grep inactive)" ] && sudo systemctl start firewalld
        sudo firewall-cmd --permanent --zone=public --add-port=8000/tcp
        sudo firewall-cmd --reload
    else
        sudo iptables -A INPUT -m state --state NEW -p tcp --dport 8000 -j ACCEPT
        sudo iptables-save | sudo tee /etc/sysconfig/iptables
    fi

fi

# Helpful info
# Vagrant reserves eth0 for NAT, so this will give you eth1 IP if eth0 exists (assuming its for NAT)
# This may not be helpful if machine is already provisoined and has advanced network config
if [ -z "$(hostname -I | awk '{print $2}')" ]
then
    IPADDR="$(hostname -I)"
else
    IPADDR="$(hostname -I | awk '{print $2}')"
fi

echo "Access Jenkins via browser from http://$IPADDR:8000 in about 10 seconds."