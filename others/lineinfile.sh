#!/bin/bash
for port in 8091 8092; do
sudo sed -i "s/port/$port/g" /home/fsadmin/playbooks/lineinfile.yml
ansible-playbook /home/fsadmin/playbooks/lineinfile.yml;
sudo sed -i "s/$port/port/g" /home/fsadmin/playbooks/lineinfile.yml
done
