#dependency: golang role
redis_ip=$(/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:")
redis_port=(6379 6380 6381)
redis_password=fred
redis_exporter_listen=9121
redis=''
for port in ${redis_port[*]} ;
do
  if [ -n "$redis" ]
  then
    redis="$redis","redis://$redis_ip:$port"
  else
    redis="redis://$redis_ip:$port"
  fi
done

# mkdir -p ~/go/src/github.com/oliver006
# cd ~/go/src/github.com/oliver006
# wget https://github.com/oliver006/redis_exporter/archive/master.zip
# unzip master.zip
# mv ~/go/src/github.com/oliver006/redis_exporter{-master,}
go get github.com/oliver006/redis_exporter
cd $GOPATH/src/github.com/oliver006/redis_exporter
go build
sudo mv $GOPATH/src/github.com/oliver006/redis_exporter/redis_exporter /bin/redis-exporter
sudo firewall-cmd --add-port=$redis_exporter_listen/tcp
sudo firewall-cmd --runtime-to-permanent
sudo bash -c "cat <<EOF > /usr/lib/systemd/system/redis-exporter.service
[Unit]
Description=Redis Exporter Service
After=network.target
Wants=network-online.target

[Service]
ExecStart=/bin/redis-exporter --redis.addr=$redis --redis.password=$redis_password --web.listen-address=0.0.0.0:$redis_exporter_listen
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF"
sudo systemctl daemon-reload
sudo systemctl enable redis-exporter.service &&
sudo systemctl restart redis-exporter.service
