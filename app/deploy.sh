#!/bin/bash
app=$1
version=$2

sudo sed -i "s/version/$version/g" /home/admin/myapp/service.sh
bash -c 'cat <<EOF > /home/admin/myapp/deploy.yml
- hosts:
    - BSLSVRRMTSAP'$app'01
    - BSLSVRRMTSAP'$app'02
  become: yes
  tasks:
    - name: copy jar file
      copy:
        src: /home/admin/myapp/RMAP'$app'-'$version'.jar
        dest: /home/admin/myapp/RMAP'$app'-'$version'.jar
    - name: configure service
      script: service.sh
EOF'
ansible-playbook /home/admin/myapp/deploy.yml
sudo sed -i "s/$version/version/g" /home/admin/myapp/service.sh
