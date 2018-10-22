sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce
sudo sed -i 's%ExecStart=/usr/bin/dockerd%ExecStart=/usr/bin/dockerd --registry-mirror=https://fp84p7m8.mirror.aliyuncs.com%g' /usr/lib/systemd/system/docker.service
sudo systemctl daemon-reload
sudo systemctl enable docker && sudo systemctl start docker

swapoff -a && sysctl -w vm.swappiness=0
sudo sed '/swap/d' -i /etc/fstab
for port in 6443 2379-2380 10250 10251 10252 9099;do
  sudo firewall-cmd --add-port=$port/tcp
done
sudo firewall-cmd --runtime-to-permanent
sudo bash -c "cat << EOF > /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF"
sudo sysctl -p /etc/sysctl.d/k8s.conf
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

echo '*/30 * * * * /usr/sbin/ntpdate time7.aliyun.com >/dev/null 2>&1' > /tmp/crontab2.tmp
sudo crontab /tmp/crontab2.tmp
sudo systemctl enable ntpdate.service && sudo systemctl start ntpdate.service
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf
echo "* soft nproc 65536"  >> /etc/security/limits.conf
echo "* hard nproc 65536"  >> /etc/security/limits.conf
echo "* soft  memlock  unlimited"  >> /etc/security/limits.conf
echo "* hard memlock  unlimited"  >> /etc/security/limits.conf
sudo bash -c "cat <<EOF > /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
172.16.0.18 k8s01
172.16.0.19 k8s02
172.16.0.20 k8s03
172.16.0.22 k8s04
172.16.0.23 k8s05
EOF"
# k8s01
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
chmod +x cfssl_linux-amd64
sudo mv cfssl_linux-amd64 /usr/local/bin/cfssl
chmod +x cfssljson_linux-amd64
sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
chmod +x cfssl-certinfo_linux-amd64
sudo mv cfssl-certinfo_linux-amd64 /usr/local/bin/cfssl-certinfo
ssh-keygen -f ~/.ssh/id_rsa -N ""
ssh-copy-id admin@k8s02
ssh-copy-id admin@k8s03
mkdir ~/ssl
cd ~/ssl
cat <<EOF > ca-config.json
{
"signing": {
"default": {
  "expiry": "8760h"
},
"profiles": {
  "kubernetes-Soulmate": {
    "usages": [
        "signing",
        "key encipherment",
        "server auth",
        "client auth"
    ],
    "expiry": "8760h"
  }
}
}
}
EOF
cat <<EOF > ca-csr.json
{
"CN": "kubernetes-Soulmate",
"key": {
"algo": "rsa",
"size": 2048
},
"names": [
{
  "C": "CN",
  "ST": "shanghai",
  "L": "shanghai",
  "O": "k8s",
  "OU": "System"
}
]
}
EOF
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
cat <<EOF > etcd-csr.json
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    "172.16.0.18",
    "172.16.0.19",
    "172.16.0.20"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "shanghai",
      "L": "shanghai",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json \
-profile=kubernetes-Soulmate etcd-csr.json | cfssljson -bare etcd
sudo mkdir -p /etc/etcd/ssl
sudo cp etcd.pem etcd-key.pem ca.pem /etc/etcd/ssl/
sudo chmod 604 /etc/etcd/ssl/etcd-key.pem
scp -r /etc/etcd/ssl/*.pem k8s02:~
scp -r /etc/etcd/ssl/*.pem k8s03:~
ssh -n k8s02 "sudo mkdir -p /etc/etcd/ssl && sudo mv ~/*.pem /etc/etcd/ssl && sudo chmod 600 /etc/etcd/ssl/etcd-key.pem && exit"
ssh -n k8s03 "sudo mkdir -p /etc/etcd/ssl && sudo mv ~/*.pem /etc/etcd/ssl && sudo chmod 600 /etc/etcd/ssl/etcd-key.pem && exit"
sudo chmod 600 /etc/etcd/ssl/etcd-key.pem
sudo yum install -y etcd
hostname=$(hostname)
etcd01=k8s01
etcd02=k8s02
etcd03=k8s03
etcd01IP=172.16.0.18
etcd02IP=172.16.0.19
etcd03IP=172.16.0.20
sudo bash -c "cat <<EOF >/usr/lib/systemd/system/etcd.service
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/coreos

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
ExecStart=/usr/bin/etcd \
  --name $hostname \
  --cert-file=/etc/etcd/ssl/etcd.pem \
  --key-file=/etc/etcd/ssl/etcd-key.pem \
  --peer-cert-file=/etc/etcd/ssl/etcd.pem \
  --peer-key-file=/etc/etcd/ssl/etcd-key.pem \
  --trusted-ca-file=/etc/etcd/ssl/ca.pem \
  --peer-trusted-ca-file=/etc/etcd/ssl/ca.pem \
  --initial-advertise-peer-urls https://$etcd01IP:2380 \
  --listen-peer-urls https://$etcd01IP:2380 \
  --listen-client-urls https://$etcd01IP:2379,http://127.0.0.1:2379 \
  --advertise-client-urls https://$etcd01IP:2379 \
  --initial-cluster-token etcd-cluster-0 \
  --initial-cluster $etcd01=https://$etcd01IP:2380,$etcd02=https://$etcd02IP:2380,$etcd03=https://$etcd03IP:2380 \
  --initial-cluster-state new \
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF"
# etcd02 Service
hostname=$(hostname)
etcd01=k8s01
etcd02=k8s02
etcd03=k8s03
etcd01IP=172.16.0.18
etcd02IP=172.16.0.19
etcd03IP=172.16.0.20
sudo bash -c "cat <<EOF >/usr/lib/systemd/system/etcd.service
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/coreos

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
ExecStart=/usr/bin/etcd \
  --name $hostname \
  --cert-file=/etc/etcd/ssl/etcd.pem \
  --key-file=/etc/etcd/ssl/etcd-key.pem \
  --peer-cert-file=/etc/etcd/ssl/etcd.pem \
  --peer-key-file=/etc/etcd/ssl/etcd-key.pem \
  --trusted-ca-file=/etc/etcd/ssl/ca.pem \
  --peer-trusted-ca-file=/etc/etcd/ssl/ca.pem \
  --initial-advertise-peer-urls https://$etcd02IP:2380 \
  --listen-peer-urls https://$etcd02IP:2380 \
  --listen-client-urls https://$etcd02IP:2379,http://127.0.0.1:2379 \
  --advertise-client-urls https://$etcd02IP:2379 \
  --initial-cluster-token etcd-cluster-0 \
  --initial-cluster $etcd01=https://$etcd01IP:2380,$etcd02=https://$etcd02IP:2380,$etcd03=https://$etcd03IP:2380 \
  --initial-cluster-state new \
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF"
# etcd03 Service
hostname=$(hostname)
etcd01=k8s01
etcd02=k8s02
etcd03=k8s03
etcd01IP=172.16.0.18
etcd02IP=172.16.0.19
etcd03IP=172.16.0.20
sudo bash -c "cat <<EOF >/usr/lib/systemd/system/etcd.service
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/coreos

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
ExecStart=/usr/bin/etcd \
  --name $hostname \
  --cert-file=/etc/etcd/ssl/etcd.pem \
  --key-file=/etc/etcd/ssl/etcd-key.pem \
  --peer-cert-file=/etc/etcd/ssl/etcd.pem \
  --peer-key-file=/etc/etcd/ssl/etcd-key.pem \
  --trusted-ca-file=/etc/etcd/ssl/ca.pem \
  --peer-trusted-ca-file=/etc/etcd/ssl/ca.pem \
  --initial-advertise-peer-urls https://$etcd03IP:2380 \
  --listen-peer-urls https://$etcd03IP:2380 \
  --listen-client-urls https://$etcd03IP:2379,http://127.0.0.1:2379 \
  --advertise-client-urls https://$etcd03IP:2379 \
  --initial-cluster-token etcd-cluster-0 \
  --initial-cluster $etcd01=https://$etcd01IP:2380,$etcd02=https://$etcd02IP:2380,$etcd03=https://$etcd03IP:2380 \
  --initial-cluster-state new \
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF"
sudo systemctl daemon-reload
sudo systemctl enable etcd && sudo systemctl start etcd
sudo systemctl status etcd
sudo etcdctl --endpoints=https://$etcd01IP:2379,https://$etcd02IP:2379,https://$etcd03IP:2379 \
--ca-file=/etc/etcd/ssl/ca.pem \
--cert-file=/etc/etcd/ssl/etcd.pem \
--key-file=/etc/etcd/ssl/etcd-key.pem  cluster-health

sudo yum install -y keepalived
sudo systemctl enable keepalived
sudo bash -c 'cat <<EOF > /etc/keepalived/keepalived.conf
global_defs {
   router_id LVS_k8s
}

vrrp_script CheckK8sMaster {
    script "curl -k https://172.16.0.21:6443"
    interval 3
    timeout 9
    fall 2
    rise 2
}

vrrp_instance VI_1 {
    state MASTER
    interface ens33
    virtual_router_id 61
    priority 100
    advert_int 1
    mcast_src_ip 172.16.0.18
    nopreempt
    authentication {
        auth_type PASS
        auth_pass sqP05dQgMSlzrxHj
    }
    unicast_peer {
        172.16.0.19
        172.16.0.20
    }
    virtual_ipaddress {
        172.16.0.21/24
    }
    track_script {
        CheckK8sMaster
    }

}
EOF'
# k8s02
sudo bash -c 'cat <<EOF > /etc/keepalived/keepalived.conf
global_defs {
   router_id LVS_k8s
}

global_defs {
   router_id LVS_k8s
}

vrrp_script CheckK8sMaster {
    script "curl -k https://172.16.0.21:6443"
    interval 3
    timeout 9
    fall 2
    rise 2
}

vrrp_instance VI_1 {
    state BACKUP
    interface ens33
    virtual_router_id 61
    priority 90
    advert_int 1
    mcast_src_ip 172.16.0.19
    nopreempt
    authentication {
        auth_type PASS
        auth_pass sqP05dQgMSlzrxHj
    }
    unicast_peer {
        172.16.0.18
        172.16.0.20
    }
    virtual_ipaddress {
        172.16.0.21/24
    }
    track_script {
        CheckK8sMaster
    }

}
EOF'
# k8s03
sudo bash -c 'cat <<EOF > /etc/keepalived/keepalived.conf
global_defs {
   router_id LVS_k8s
}

global_defs {
   router_id LVS_k8s
}

vrrp_script CheckK8sMaster {
    script "curl -k https://172.16.0.21:6443"
    interval 3
    timeout 9
    fall 2
    rise 2
}

vrrp_instance VI_1 {
    state BACKUP
    interface ens33
    virtual_router_id 61
    priority 80
    advert_int 1
    mcast_src_ip 172.16.0.20
    nopreempt
    authentication {
        auth_type PASS
        auth_pass sqP05dQgMSlzrxHj
    }
    unicast_peer {
        172.16.0.18
        172.16.0.19
    }
    virtual_ipaddress {
        172.16.0.21/24
    }
    track_script {
        CheckK8sMaster
    }

}
EOF'
sudo systemctl start keepalived

sudo bash -c "cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF"
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo sed -i 's%KUBELET_EXTRA_ARGS=%KUBELET_EXTRA_ARGS=--fail-swap-on=false%g' /etc/sysconfig/kubelet
sudo systemctl daemon-reload
sudo systemctl enable kubelet
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc

sudo docker pull registry.cn-hangzhou.aliyuncs.com/haroldwo/coredns:1.2.2
sudo docker pull registry.cn-hangzhou.aliyuncs.com/haroldwo/kube-apiserver:v1.12.1
sudo docker pull registry.cn-hangzhou.aliyuncs.com/haroldwo/kube-controller-manager:v1.12.1
sudo docker pull registry.cn-hangzhou.aliyuncs.com/haroldwo/kube-proxy:v1.12.1
sudo docker pull registry.cn-hangzhou.aliyuncs.com/haroldwo/kube-scheduler:v1.12.1
sudo docker pull registry.cn-hangzhou.aliyuncs.com/haroldwo/pause:3.1
sudo docker tag registry.cn-hangzhou.aliyuncs.com/haroldwo/coredns:1.2.2 k8s.gcr.io/coredns:1.2.2
sudo docker tag registry.cn-hangzhou.aliyuncs.com/haroldwo/kube-apiserver:v1.12.1 k8s.gcr.io/kube-apiserver:v1.12.1
sudo docker tag registry.cn-hangzhou.aliyuncs.com/haroldwo/kube-controller-manager:v1.12.1 k8s.gcr.io/kube-controller-manager:v1.12.1
sudo docker tag registry.cn-hangzhou.aliyuncs.com/haroldwo/kube-proxy:v1.12.1 k8s.gcr.io/kube-proxy:v1.12.1
sudo docker tag registry.cn-hangzhou.aliyuncs.com/haroldwo/kube-scheduler:v1.12.1 k8s.gcr.io/kube-scheduler:v1.12.1
sudo docker tag registry.cn-hangzhou.aliyuncs.com/haroldwo/pause:3.1 k8s.gcr.io/pause:3.1
k8s01=172.16.0.18
k8s02=172.16.0.19
k8s03=172.16.0.20
k8svip=172.16.0.21
k8s04=172.16.0.22
k8s05=172.16.0.23
cat <<EOF > kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1alpha3
kind: ClusterConfiguration
kubernetesVersion: stable
apiServerCertSANs:
- k8s01
- k8s02
- k8s03
- $k8s01
- $k8s02
- $k8s03
- $k8s04
- $k8s05
- $k8svip
etcd:
  external:
    endpoints:
    - https://$k8s01:2379
    - https://$k8s02:2379
    - https://$k8s03:2379
    caFile: /etc/etcd/ssl/ca.pem
    certFile: /etc/etcd/ssl/etcd.pem
    keyFile: /etc/etcd/ssl/etcd-key.pem
    dataDir: /var/lib/etcd
networking:
  podSubnet: "192.168.0.0/16"
api:
  advertiseAddress: "$k8svip"
token: "b99a00.a144ef80536d4344"
tokenTTL: "0s"
featureGates:
  CoreDNS: true
EOF
sudo kubeadm init --config kubeadm-config.yaml

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
sudo scp -r /etc/kubernetes/pki  root@k8s02:/etc/kubernetes/
sudo scp -r /etc/kubernetes/pki  root@k8s03:/etc/kubernetes/
kubectl apply -f https://docs.projectcalico.org/v3.2/getting-started/kubernetes/installation/rbac.yaml
curl https://docs.projectcalico.org/v3.2/getting-started/kubernetes/installation/hosted/calico.yaml -O
sudo sed -i 's%"http://10.96.232.136:6666"%"http://172.16.0.18:2379,http://172.16.0.19:2379,http://172.16.0.20:2379"%g' calico.yaml
sudo sed -i 's%etcd_ca: ""%etcd_ca: "/etc/etcd/ssl/ca.pem"%g' calico.yaml
sudo sed -i 's%etcd_cert: ""%etcd_cert: "/etc/etcd/ssl/etcd.pem"%g' calico.yaml
sudo sed -i 's%etcd_key: ""%etcd_key: "/etc/etcd/ssl/etcd-key.pem"%g' calico.yaml
kubectl apply -f calico.yaml

kubeadm join 172.16.0.18:6443 --token qysivj.un7qx9cwokns7bm6 --discovery-token-ca-cert-hash sha256:6187cd2f8443584d0dbf647ef297f4f3f79f7ef01e8b142755e55861ea909f22

for port in 10250;do
  sudo firewall-cmd --add-port=$port/tcp
done
sudo firewall-cmd --runtime-to-permanent
