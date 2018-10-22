#!/bin/bash
redis_version=stable
redis_port=(6379 6380 6381)
redis_password=fred
localhost=$(/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:")

sudo yum -y install gcc wget tcl ntp
sudo systemctl start ntpd
ntpdate time.nist.gov
wget http://download.redis.io/releases/redis-$redis_version.tar.gz
sudo tar -zxvf redis-$redis_version.tar.gz -C /usr/local/src/
cd /usr/local/src/redis-$redis_version
sudo make
cd /usr/local/src/redis-$redis_version/src
sudo mv mkreleasehdr.sh redis-benchmark redis-check-aof redis-check-rdb redis-cli redis-server /usr/local/bin
for port in ${redis_port[*]} ;do
sudo mkdir -p /usr/local/redis-cluster/$port ;
sudo cp /usr/local/src/redis-$redis_version/redis.conf /usr/local/redis-cluster/$port/redis.conf ;
sudo sed -i "s/daemonize no/daemonize yes/g" /usr/local/redis-cluster/$port/redis.conf ;
sudo sed -i "s/bind 127.0.0.1/bind $localhost/g" /usr/local/redis-cluster/$port/redis.conf ;
sudo sed -i "s/port 6379/port $port/g" /usr/local/redis-cluster/$port/redis.conf ;
sudo sed -i "s:dir .:dir /usr/local/redis-cluster/$port:g" /usr/local/redis-cluster/$port/redis.conf ;
sudo sed -i 's:logfile "":logfile:g' /usr/local/redis-cluster/$port/redis.conf ;
sudo sed -i "s:logfile:logfile /usr/local/redis-cluster/$port/redis.log:g" /usr/local/redis-cluster/$port/redis.conf ;
sudo sed -i 's/# cluster-enabled yes/cluster-enabled yes/g' /usr/local/redis-cluster/$port/redis.conf ;
sudo sed -i "s/# cluster-config-file nodes-6379.conf/cluster-config-file nodes-$port.conf/g" /usr/local/redis-cluster/$port/redis.conf ;
sudo sed -i 's/# cluster-node-timeout 15000/cluster-node-timeout 5000/g' /usr/local/redis-cluster/$port/redis.conf ;
sudo sed -i 's/appendonly no/appendonly yes/g' /usr/local/redis-cluster/$port/redis.conf ;
sudo sed -i "s/# requirepass foobared/requirepass $redis_password/g" /usr/local/redis-cluster/$port/redis.conf ;
sudo sed -i "s/# masterauth <master-password>/masterauth $redis_password/g" /usr/local/redis-cluster/$port/redis.conf ;
sudo sed -i 's/slowlog-log-slower-than 10000/slowlog-log-slower-than 100000/g' /usr/local/redis-cluster/$port/redis.conf ;
sudo sed -i 's/# maxmemory <bytes>/maxmemory 1073741824/g' /usr/local/redis-cluster/$port/redis.conf ;
sudo sed -i 's/# min-slaves-to-write 3/min-slaves-to-write 1/g' /usr/local/redis-cluster/$port/redis.conf ;
sudo sed -i 's/# min-slaves-max-lag 10/min-slaves-max-lag 5/g' /usr/local/redis-cluster/$port/redis.conf ;
sudo sed -i '# cluster-migration-barrier 1/cluster-migration-barrier 1/g' /usr/local/redis-cluster/$port/redis.conf ;
sudo bash -c 'cat <<EOF >> /usr/local/redis-cluster/$port/redis.conf
rename-command FLUSHALL ""
rename-command FLUSHDB ""
rename-command KEYS ""
EOF'
sudo bash -c "echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf"
sudo bash -c "echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled"
sudo bash -c "cat <<EOF > /usr/lib/systemd/system/redis$port.service
[Unit]
Description=Redis $port Service
After=network.target
Wants=network-online.target
Wants=time-sync.target

[Service]
ExecStart=/usr/local/bin/redis-server /usr/local/redis-cluster/$port/redis.conf
Restart=on-failure
RestartSec=5
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF"
sudo systemctl daemon-reload
sudo systemctl enable redis$port.service &&
sudo systemctl restart redis$port.service
sudo firewall-cmd --add-port=$port/tcp
sudo firewall-cmd --add-port=$(($port+10000))/tcp
sudo firewall-cmd --runtime-to-permanent
done

redis_port=(6379 6380 6381)
redis_password=fred
redis_role=master
master_ip=172.16.0.13
slave_ip=172.16.0.14
localhost=$(/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:")

if [ $redis_role == master ]
then
for ip in $master_ip $slave_ip;do
  for port in ${redis_port[*]} ;do
    redis-cli -h $localhost -p ${redis_port[0]} -a $redis_password -c CLUSTER MEET $ip $port;
  done
done
for slot in {0..5500};do
  redis-cli -h $master_ip -p ${redis_port[0]} -a $redis_password -c CLUSTER ADDSLOTS $slot;
done
for slot in {5501..11000};do
  redis-cli -h $master_ip -p ${redis_port[1]} -a $redis_password -c CLUSTER ADDSLOTS $slot;
done
for slot in {11001..16383};do
  redis-cli -h $master_ip -p ${redis_port[2]} -a $redis_password -c CLUSTER ADDSLOTS $slot;
done
for port in ${redis_port[*]} ;do
  master_id=$(sudo cat /usr/local/redis-cluster/$port/nodes-$port.conf | grep $master_ip:$port | awk '{print $1}');
echo $master_id
done
elif [ $redis_role == slave ]
then
  echo "Sorry, slave redis_cli feature will be completed in ansible."
else
  echo "redis_role error"
fi

#executed on slave
redis_port=(6379 6380 6381)
redis_password=fred
slave_ip=172.16.0.14

redis-cli -h $slave_ip -p ${redis_port[0]} -a $redis_password -c CLUSTER REPLICATE $master_id1;
redis-cli -h $slave_ip -p ${redis_port[1]} -a $redis_password -c CLUSTER REPLICATE $master_id2;
redis-cli -h $slave_ip -p ${redis_port[2]} -a $redis_password -c CLUSTER REPLICATE $master_id3;

#
redis_port=(10379 10380 10381)
for port in ${redis_port[*]} ;
do
sudo systemctl stop redis$port;
sudo rm -f /usr/local/redis-cluster/$port/{appendonly.aof,dump.rdb};
sudo systemctl restart redis$port;
done

redis-cli -h $localhost -p $port -a $redis_password -c CLUSTER NODES

#by Ruby way
sudo yum -y install ruby rubygems
sudo gem sources --add https://gems.ruby-china.org/ --remove https://rubygems.org/
sudo gem install redis --version 3.0.0
sudo /usr/local/src/redis-$redis_version/src/redis-trib.rb create --replicas 1 10.10.20.106:1079 10.10.20.106:1080 10.10.20.106:1081 10.10.20.107:1079 10.10.20.107:1080 10.10.20.107:1081
