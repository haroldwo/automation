wget http://github.com/hnlq715/nginx-vts-exporter/releases/download/v0.10.3/nginx-vts-exporter-0.10.3.linux-amd64.tar.gz
tar zxf nginx-vts-exporter-0.10.3.linux-amd64.tar.gz
sudo mv nginx-vts-exporter-0.10.3.linux-amd64/nginx-vts-exporter /bin/nginx-vts-exporter
sudo vi /bin/nginx-vts-exporter.sh
---
#!/bin/sh
NGINX_HOST="http://localhost:9013"
METRICS_ENDPOINT="/metrics"
METRICS_ADDR=":19913"
DEFAULT_METRICS_NS="nginx"

set -eo pipefail
default_status="$NGINX_HOST/status/format/json"
NGINX_STATUS=${NGINX_STATUS:-$default_status}
METRICS_NS=${METRICS_NS:-$DEFAULT_METRICS_NS}

# If there are any arguments then we want to run those instead
#if [[ "$1" == "$binary" || -z $1 ]]; then
#  exec "$@"
#else
#  echo "Running the default"
#echo "[$0] - Nginx scrape host --> [$NGINX_STATUS]"
#echo "[$0] - Metrics Address   --> [$METRICS_ADDR]"
#echo "[$0] - Metrics Endpoint  --> [$METRICS_ENDPOINT]"
#echo "[$0] - Metrics Namespace  --> [$METRICS_NS]"
#echo "[$0] - Running metrics nginx-vts-exporter"

exec nginx-vts-exporter -nginx.scrape_uri=$NGINX_STATUS -telemetry.address $METRICS_ADDR -telemetry.endpoint $METRICS_ENDPOINT -metrics.namespace $METRICS_NS
#fi
---
sudo chmod a+x /bin/nginx-vts-exporter.sh
sudo firewall-cmd --add-port=19913/tcp
sudo firewall-cmd --runtime-to-permanent
sudo bash -c "cat <<EOF > /usr/lib/systemd/system/nginx-vts-exporter.service
[Unit]
Description=Nginx VTS Exporter Service
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
User=fsadmin
Group=fsadmin
ExecStart=/bin/nginx-vts-exporter.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF"
sudo systemctl daemon-reload
sudo systemctl start nginx-vts-exporter.service
sudo systemctl enable nginx-vts-exporter.service
