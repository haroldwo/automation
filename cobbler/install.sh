manually modify tftp #sudo sed -i 's/yes/no/2' /etc/xinetd.d/tftp
manually install debmirrors #if you need
choose fence-agents to install #yum search fence-agents
#Important: if you have n ISO files to install, you need prepare (2 x n x capacity of ISO) free disk space at less

#!/bin/bash
pass=$(openssl passwd -1 "redhat")
dhcpRange=172.16.0.230 172.16.0.249

localhost=$(/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:")
net=$(echo $localhost | awk 'BEGIN{FS=OFS="."}{$NF=0;print}')
gateway=$(cat /etc/sysconfig/network-scripts/ifcfg-e* | grep GATEWAY | awk -F = '{print $2}')
dns=$(cat /etc/sysconfig/network-scripts/ifcfg-e* | grep DNS1 | awk -F = '{print $2}')

sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum -y install cobbler pykickstart fence-agents dhcp xinetd
sudo sed -i '/default_password_crypted/d' /etc/cobbler/settings
sudo sed -i '/and put the output between the/a\default_password_crypted: "'"$pass"'"' /etc/cobbler/settings
sudo sed -i 's/server: 127.0.0.1/server: '"$localhost"'/g' /etc/cobbler/settings
sudo sed -i 's/func_auto_setup: 0/func_auto_setup: 1/g' /etc/cobbler/settings
sudo sed -i 's/register_new_installs: 0/register_new_installs: 1/g' /etc/cobbler/settings
sudo sed -i 's/anamon_enabled: 0/anamon_enabled: 1/g' /etc/cobbler/settings
sudo sed -i 's/subnet 192.168.1.0/subnet '"$net"'/g' /etc/cobbler/dhcp.template
sudo sed -i 's/option routers             192.168.1.5/option routers             '"$gateway"'/g' /etc/cobbler/dhcp.template
sudo sed -i 's/option domain-name-servers 192.168.1.1/option domain-name-servers '"$dns"'/g' /etc/cobbler/dhcp.template
sudo sed -i 's/range dynamic-bootp        192.168.1.100 192.168.1.254/range dynamic-bootp        '"$dhcpRange"'/g' /etc/cobbler/dhcp.template
sudo setenforce 0
sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
cobbler get-loaders
mkdir -p /usr/share/cobbler/web
sudo setsebool -P httpd_can_network_connect true
sudo firewall-cmd --add-service=http
sudo firewall-cmd --add-port=80/tcp
sudo firewall-cmd --add-port=69/udp
sudo firewall-cmd --add-port=51234-51235/tcp
sudo firewall-cmd --runtime-to-permanent
sudo systemctl enable cobblerd &&
sudo systemctl start cobblerd
sudo systemctl enable httpd &&
sudo systemctl start httpd
sudo systemctl enable rsyncd &&
sudo systemctl start rsyncd
sudo systemctl enable dhcpd &&
sudo systemctl start dhcpd
sudo systemctl enable xinetd &&
sudo systemctl start xinetd
cobbler sync
