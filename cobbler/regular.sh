#!/bin/bash
ansible_pass=admin
ansible_account=admin
ansible_key=http://172.16.0.10/cobbler/pub/id_rsa.pub

useradd $ansible_account
echo "$ansible_pass" | passwd $ansible_account --stdin
echo "$ansible_account ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config
runuser -l $ansible_account -c "wget $ansible_key -P /home/$ansible_account/"
runuser -l $ansible_account -c "mkdir -p /home/$ansible_account/.ssh"
runuser -l $ansible_account -c "cat /home/$ansible_account/id_rsa.pub >> /home/$ansible_account/.ssh/authorized_keys"
runuser -l $ansible_account -c "chmod 700 /home/$ansible_account/.ssh"
runuser -l $ansible_account -c "chmod 600 /home/$ansible_account/.ssh/authorized_keys"
