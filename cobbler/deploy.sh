cobbler system add --name=ansible --profile=CentOS-7-x86_64
cobbler system edit --name=ansible --interface=ens33 --mac=00:50:56:3D:16:32 \
--ip-address=172.16.0.12 --netmask=255.255.255.0 --static=1 --dns-name=ansible.mydomain.com \
--name-servers=172.16.0.253 --kickstart=/var/lib/cobbler/kickstarts/ansible.ks \
--if-gateway=172.16.0.253 --hostname=ansible

#!/bin/bash
localhost=$(/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:")
packages=$(sed ':a;N;s/\n/\\n/g;ba' ./packages)
script="ansible.sh"
kickstart=ansible.ks

sudo sed -i 's%America/New_York%Asia/Shanghai%g' /var/lib/cobbler/kickstarts/sample_end.ks
cp /var/lib/cobbler/kickstarts/sample_end.ks /var/lib/cobbler/kickstarts/$kickstart
sudo sed -i "s/^func/$packages/g" /var/lib/cobbler/snippets/func_install_if_enabled
sudo sed -i "/boot notification/i\systemctl set-default multi-user.target" /var/lib/cobbler/kickstarts/$kickstart
sudo sed -i "/boot notification/i\wget http:\/\/$localhost\/cobbler\/pub\/$script" /var/lib/cobbler/kickstarts/$kickstart
sudo sed -i "/boot notification/i\chmod a+x $script" /var/lib/cobbler/kickstarts/$kickstart
sudo sed -i "/boot notification/i\. $script" /var/lib/cobbler/kickstarts/$kickstart
cobbler validateks /var/lib/cobbler/kickstarts/$kickstart
cobbler sync

scp admin@172.16.0.12:/home/admin/.ssh/id_rsa.pub /var/www/cobbler/pub

#use upper script
script=regular.sh
kickstart=regular.ks

cobbler system add --name=regular01 --profile=CentOS-7-x86_64
cobbler system add --name=regular02 --profile=CentOS-7-x86_64
cobbler system add --name=regular03 --profile=CentOS-7-x86_64
cobbler system edit --name=regular01 --interface=ens33 --mac=00:50:56:30:05:81 \
--ip-address=172.16.0.18 --netmask=255.255.255.0 --static=1 --dns-name=k8s01.mydomain.com \
--name-servers=172.16.0.253 --kickstart=/var/lib/cobbler/kickstarts/regular.ks \
--if-gateway=172.16.0.253 --hostname=k8s01
cobbler system edit --name=regular02 --interface=ens33 --mac=00:50:56:2E:9C:91 \
--ip-address=172.16.0.19 --netmask=255.255.255.0 --static=1 --dns-name=k8s02.mydomain.com \
--name-servers=172.16.0.253 --kickstart=/var/lib/cobbler/kickstarts/regular.ks \
--if-gateway=172.16.0.253 --hostname=k8s02
cobbler system edit --name=regular02 --interface=ens33 --mac=00:50:56:2A:01:E2 \
--ip-address=172.16.0.20 --netmask=255.255.255.0 --static=1 --dns-name=k8s03.mydomain.com \
--name-servers=172.16.0.253 --kickstart=/var/lib/cobbler/kickstarts/regular.ks \
--if-gateway=172.16.0.253 --hostname=k8s03
