ssh root@10.10.80.33
sudo yum -y install glusterfs glusterfs-server policycoreutils-python expect
sudo iptables -I INPUT -p all -s 10.10.80.33 -j ACCEPT
sudo iptables -I INPUT -p all -s 10.10.80.34 -j ACCEPT
sudo firewall-cmd --add-service=glusterfs
sudo firewall-cmd --runtime-to-permanent
sudo mkdir /var/log/glusterfs/
sudo systemctl start glusterd
sudo systemctl enable glusterd

dev=sdc
sudo gluster peer probe 10.10.80.34
bash -c 'cat <<EOF > /home/fsadmin/expect_fdisk.sh
#!/usr/bin/expect
set timeout 10;
spawn sudo fdisk /dev/'$dev';
expect Command*
send "n\r"
expect Select*
send "\r"
expect Partition*
send "\r"
expect First*
send "\r"
expect Last*
send "\r"
expect Command*
send "t\r"
expect Hex*
send "8e\r"
expect Command*
send "w\r"
EOF'
expect -f /home/fsadmin/expect_fdisk.sh
sudo partprobe
sudo pvcreate /dev/$dev
sudo vgcreate vg_bricks /dev/$dev
sudo lvcreate -L 495G -T vg_bricks/thinpool
for lv in {01..10}; do
  lvmount=/bricks/data
  brick=datavol$lv
  sudo lvcreate -V 10G -T vg_bricks/thinpool -n thinvol$lv;
  sudo mkfs -t xfs -i size=512 /dev/vg_bricks/thinvol$lv;
  sudo mkdir -p $lvmount
  sudo bash -c 'echo "/dev/vg_bricks/thinvol'$lv' '$lvmount' xfs defaults 1 2" >> /etc/fstab'
  sudo umount $lvmount
  sudo mount $lvmount
  sudo mkdir $lvmount/$brick
  sudo bash -c "semanage fcontext -a -t glusterd_brick_t $lvmount/$brick"
  sudo restorecon -Rv $lvmount/$brick
done

for num in {01..10}; do
  sudo gluster volume create gfsvol$num replica 2 10.10.80.33:/bricks/data/datavol$num 10.10.80.34:/bricks/data/datavol$num force;
  sudo gluster volume set gfsvol$num auth.allow 10.10.*.*;
  sudo gluster volume start gfsvol$num;
done

sudo mkdir /mnt/data
sudo bash -c 'echo "10.10.80.33:/gfsvol01 /mnt/data glusterfs net_dev,defaults 0 0" >> /etc/fstab'
sudo mount /mnt/data
sudo chown fsadmin:fsadmin /mnt/data

sed -i "s/allowed_hosts=127.0.0.1/allowed_hosts=127.0.0.1,manager.lab.example.com/g" /etc/nagios/nrpe.cfg
for lv in {01..10}; do
  lvmount=/bricks/data
  brick=datavol$lv
  sudo gluster volume stop gfsvol$lv
  sudo gluster volume delete gfsvol$lv
  sudo rm -rf $lvmount/$brick
  sudo mkdir $lvmount/$brick
  sudo bash -c "semanage fcontext -a -t glusterd_brick_t $lvmount/$brick"
  sudo restorecon -Rv $lvmount/$brick
done
