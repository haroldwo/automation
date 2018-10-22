#!/bin/bash
ansible_pass=admin
ansible_account=admin

wget https://bootstrap.pypa.io/get-pip.py --no-check-certificate
python get-pip.py
pip install http://github.com/diyan/pywinrm/archive/master.zip#egg=pywinrm
pip install --upgrade pip
pip install pyvmomi
yum -y install epel-release expect
yum -y install ansible
useradd $ansible_account
echo "$ansible_pass" | passwd $ansible_account --stdin
echo "$ansible_account ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
runuser -l $ansible_account -c 'ssh-keygen -f ~/.ssh/id_rsa -N ""'
