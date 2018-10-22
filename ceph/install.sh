# All nodes
sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
sudo yum install -y http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
sudo yum --enablerepo=elrepo-kernel install -y kernel-lt
sudo sed -i 's%GRUB_DEFAULT=saved%GRUB_DEFAULT=0%g' /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo reboot

release=mimic

oldKernel=$(sudo cat /boot/grub2/grub.cfg | grep 'x (3' | awk -F '(' '{print $2}' | awk -F ')' '{print $1}')
sudo yum -y autoremove kernel-$oldKernel
sudo yum install -y deltarpm https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm yum-plugin-priorities
sudo setenforce 0
sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
sudo bash -c 'cat << EOF >> /etc/hosts
172.16.0.12 admin
172.16.0.15 ceph01
172.16.0.16 ceph02
172.16.0.17 ceph03
EOF'
sudo bash -c "cat << EOF > /etc/yum.repos.d/ceph.repo
[ceph-noarch]
name=Ceph noarch packages
baseurl=http://hk.ceph.com/rpm-$release/el7/noarch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=http://hk.ceph.com/keys/release.asc
priority=1
EOF"
sudo yum -y update
# admin node
sudo yum -y install ceph-deploy
mkdir my-cluster
cd my-cluster

# Nodes
sudo yum -y install ntp ntpdate ntp-doc
sudo ntpdate cn.pool.ntp.org
for port in 6789 6800-7300 7480 9283;do
  sudo firewall-cmd --add-port=$port/tcp
done
for service in ceph-mon ceph;do
  sudo firewall-cmd --zone=public --add-service=$service
done
sudo firewall-cmd --runtime-to-permanent
