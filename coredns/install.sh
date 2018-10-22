sudo bash -c "cat <<EOF > /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
172.16.0.10 genesis.example.org
172.16.0.18 k8s01.example.org
172.16.0.19 k8s02.example.org
172.16.0.20 k8s03.example.org
172.16.0.21 k8s04.example.org
172.16.0.22 k8s05.example.org
EOF"
sudo mkdir -p /etc/coredns/
sudo bash -c 'cat << EOF > /etc/coredns/Corefile
example.org {
    hosts
    log
    reload
}
. {
    forward . /etc/resolv.conf
    log
    reload
}
EOF'
sudo bash -c 'cat << EOF > /usr/lib/systemd/system/coredns.service
[Unit]
Description=CoreDNS Service
After=network.target
Wants=network-online.target
Wants=time-sync.target

[Service]
ExecStart=/usr/local/bin/coredns -conf /etc/coredns/Corefile
Restart=on-failure
RestartSec=5
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF'
sudo systemctl daemon-reload
sudo systemctl enable coredns.service &&
sudo systemctl start coredns.service
