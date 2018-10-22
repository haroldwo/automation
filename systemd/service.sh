app=$(ls /home/admin/myapp/ | grep rm)

sudo bash -c "cat <<EOF > /usr/lib/systemd/system/rmapp.service
[Unit]
Description=RiskManagement Application Service
After=network.target
After=network-online.target
Wants=network-online.target
#Documentation=
#Before=time-sync.target
#Wants=time-sync.target

[Service]
#Nice=
#Type=notify
#Type=oneshot
#Type=forking
PIDFile=/home/admin/myapp/app.pid
User=admin
Group=admin
WorkingDirectory=/home/admin/myapp
ExecStart=/bin/java -jar $app
Restart=on-failure
RestartSec=5
#RemainAfterExit=yes
#LimitNOFILE=65536
#PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF"
sudo systemctl daemon-reload
sudo systemctl start rmapp.service
sudo systemctl enable rmapp.service
