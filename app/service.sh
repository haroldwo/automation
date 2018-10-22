#!/bin/bash
app=$(ls /home/admin/myapp/ | grep version)
hostname=$(hostname)

sudo bash -c "cat <<EOF > /usr/lib/systemd/system/rmapp.service
[Unit]
Description=RiskManagement Application Service
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
PIDFile=/home/admin/myapp/app.pid
User=admin
Group=admin
WorkingDirectory=/home/admin/myapp
ExecStart=/bin/java -javaagent:/home/admin/apache-skywalking-apm-incubating/agent/skywalking-agent.jar -javaagent:/home/admin/pinpoint_agent/pinpoint-bootstrap-1.7.4-SNAPSHOT.jar -Dpinpoint.agentId=$hostname -Dpinpoint.applicationName=rmapp -jar $app
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF"
sudo systemctl daemon-reload
sudo systemctl restart rmapp.service
sudo systemctl enable rmapp.service

#ip=$(/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:" | awk 'BEGIN{FS="."}{print $4}')
