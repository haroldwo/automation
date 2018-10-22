#-
scp pub/glusterfs.ca root@workstation:/etc/ssl/glusterfs.ca
scp pub/wk.key root@workstation:/etc/ssl/glusterfs.key
scp pub/wk.pem root@workstation:/etc/ssl/glusterfs.pem
-#
ssh root@workstation
firewall-cmd --set-default-zone=trusted
firewall-cmd --runtime-to-permanent
yum -y install glusterfs glusterfs-fuse
systemctl stop glusterd
pkill glusterd
mkdir -p /var/lib/glusterd
touch /var/lib/glusterd/secure-access
#-
for var in {a..e}; do
scp pub/glusterfs.ca root@server$var:/etc/ssl/glusterfs.ca;
scp pub/server$var.key root@server$var:/etc/ssl/glusterfs.key;
scp pub/server$var.pem root@server$var:/etc/ssl/glusterfs.pem;
done
-#
ssh root@server
firewall-cmd --set-default-zone=trusted
firewall-cmd --runtime-to-permanent
systemctl stop glusterd
pkill glusterd
touch /var/lib/glusterd/secure-access
systemctl restart glusterd
fdisk
partprobe
pvcreate /dev/vdb1
vgcreate vg_bricks /dev/vdb1
lvcreate -L 10G -T vg_bricks/thinpool
if [ $(hostname) != servere ];then
for var1 in {01 02 03}; do
lvcreate -V 2G -T vg_bricks/thinpool -n thinvol$var1;
mkfs -t xfs -i size=512 /dev/vg_bricks/thinvol$var1;
done
else
lvcreate -V 10G -T vg_bricks/thinpool -n thinvol01
mkfs -t xfs -i size=512 /dev/vg_bricks/thinvol01
fi
var2=/bricks/data
var3=datavol_n1
mkdir -p $var2
echo "/dev/vg_bricks/thinvol01 $var2 xfs defaults 1 2" >> /etc/fstab
mount $var2
mkdir $var2/$var3
semanage fcontext -a -t glusterd_brick_t $var2/$var3
restorecon -Rv $var2/$var3
sed -i "s/allowed_hosts=127.0.0.1/allowed_hosts=127.0.0.1,manager.lab.example.com/g" /etc/nagios/nrpe.cfg

rmdir $var2/$var3
mkdir $var2/$var3
semanage fcontext -a -t glusterd_brick_t $var2/$var3
restorecon -Rv $var2/$var3
sed -i "s/allowed_hosts=127.0.0.1/allowed_hosts=127.0.0.1,manager.lab.example.com/g" /etc/nagios/nrpe.cfg

var=datavol
gluster volume set $var auth.allow 172.250.25.*
gluster volume set $var auth.ssl-allow '*'
gluster volume set $var server.ssl on
gluster volume set $var client.ssl on
gluster volume start $var
