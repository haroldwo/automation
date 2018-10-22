#!/bin/bash
ansible_pass=$2
ansible_account=$1

#wget http://python.org/ftp/python/2.7.9/Python-2.7.9.tgz
#tar -xvf Python-2.7.9.tgz
#cd Python-2.7.9
#./configure --prefix=/usr/local/python2.7
#make
#make install
#mv /usr/bin/python /usr/bin/python.old
#ln -s /usr/local/python2.7/bin/python2.7 /usr/bin/python
#sed -i "s/python/python2.7/g" /usr/bin/yum
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
#ssh-agent bash
#ssh-add ~/.ssh/id_rsa

#客户端sudo sed -i "/# PermitRootLogin yes/c\PermitRootLogin no" /etc/ssh/sshd_config
