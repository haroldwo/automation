#!/bin/bash
cd /etc/ansible/roles
sudo wget https://github.com/jlund/ansible-go/archive/master.zip
sudo unzip master.zip
sudo mv ansible-go-master jlund.golang
sudo rm -f master.zip
sudo sed -i 's%storage.googleapis.com%studygolang.com/dl%g' jlund.golang/vars/main.yml
sudo sed -i "/export GOPATH/i\mkdir -p ~/go/{bin,pkg,src}" /etc/ansible/roles/jlund.golang/files/go-path.sh
cat <<EOF > ~/playbooks/golang.yml
- hosts: server
  become: yes
  roles:
    - role: jlund.golang
      go_tarball: "go1.11.linux-amd64.tar.gz"
      go_tarball_checksum: "sha256:b3fcf280ff86558e0559e185b601c9eade0fd24c900b4c63cd14d1d38613e499"
      go_version_target: "go version go1.11 linux/amd64"
EOF
ansible-playbook ~/playbooks/golang.yml
