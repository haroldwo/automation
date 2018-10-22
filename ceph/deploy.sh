localhost=$(/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:")
net=$(echo $localhost | awk 'BEGIN{FS=OFS="."}{$NF=0;print}')

cd ~/my-cluster
ceph-deploy new cluster01
echo "public network = $net/24" >> ceph.conf
# because the ceph website is not stable. for every node, do the preinstall below.
sudo yum -y install ceph ceph-radosgw \
http://hk.ceph.com/rpm-mimic/el7/x86_64/ceph-mds-13.2.2-0.el7.x86_64.rpm \
http://hk.ceph.com/rpm-mimic/el7/x86_64/ceph-osd-13.2.2-0.el7.x86_64.rpm \
http://hk.ceph.com/rpm-mimic/el7/x86_64/ceph-mon-13.2.2-0.el7.x86_64.rpm \
http://hk.ceph.com/rpm-mimic/el7/x86_64/librgw2-13.2.2-0.el7.x86_64.rpm \
http://hk.ceph.com/rpm-mimic/el7/x86_64/ceph-mgr-13.2.2-0.el7.x86_64.rpm \
http://hk.ceph.com/rpm-mimic/el7/x86_64/ceph-radosgw-13.2.2-0.el7.x86_64.rpm

ceph-deploy install ceph01 ceph02 ceph03
ceph-deploy mon create-initial
ceph-deploy admin ceph01 ceph02 ceph03
ceph-deploy mgr create ceph01 # Required only for luminous+ builds, i.e >= 12.x builds
ceph-deploy osd create --data /dev/sdb ceph01
ceph-deploy osd create --data /dev/sdb ceph02
ceph-deploy osd create --data /dev/sdb ceph03
ssh ceph01 sudo ceph health
ceph-deploy mon add ceph02
ceph-deploy mon add ceph03
ceph-deploy mgr create ceph02
ceph mgr module enable prometheus
ssh ceph01 sudo ceph -s
ceph-deploy rgw create ceph01

# add keyring access to nodes
ssh ceph01 sudo chmod +r /etc/ceph/ceph.client.admin.keyring
ceph auth get-or-create client.qemu mon 'profile rbd' osd 'profile rbd pool=vms, profile rbd-read-only pool=images'
rbd create --size 1024 swimmingpool/bar

# Starting over
ceph-deploy purge {ceph-node} [{ceph-node}]
ceph-deploy purgedata {ceph-node} [{ceph-node}]
ceph-deploy forgetkeys
rm ceph.*
