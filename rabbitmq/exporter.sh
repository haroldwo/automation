wget https://github.com/kbudde/rabbitmq_exporter/releases/download/v0.29.0/rabbitmq_exporter-0.29.0.linux-amd64.tar.gz
tar -zxvf rabbitmq_exporter-0.29.0.linux-amd64.tar.gz
sudo mv rabbitmq_exporter-0.29.0.linux-amd64/rabbitmq_exporter /usr/local/bin
chown root:root /usr/local/bin/rabbitmq_exporter
sudo firewall-cmd --add-port=9419/tcp
sudo firewall-cmd --runtime-to-permanent
sudo bash -c "cat <<EOF > /usr/lib/systemd/system/rabbitmq-exporter.service
[Unit]
Description=RabbitMQ Exporter Service
After=network.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/bash -c 'PUBLISH_PORT=9419 RABBIT_CAPABILITIES=bert,no_sort /usr/local/bin/rabbitmq_exporter'
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF"
sudo systemctl daemon-reload
sudo systemctl enable rabbitmq-exporter.service &&
sudo systemctl restart rabbitmq-exporter.service

# https://github.com/kbudde/rabbitmq_exporter
