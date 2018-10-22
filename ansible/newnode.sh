#!/bin/bash
for((i=1;i<=$(cat nodeInfo | wc -l);i++));
do
  node_alias=$(awk "NR==$i{print \$1}" nodeInfo);
  node_ip=$(awk "NR==$i{print \$2}" nodeInfo);
  node_group="\[$(awk "NR==$i{print \$3}" nodeInfo)\]";
  if [ ! -n "$(cat /etc/ansible/hosts | grep $node_group)" ] ;then
    sudo bash -c "echo $node_group >> /etc/ansible/hosts"
  fi
  if [ ! -n "$(cat /etc/ansible/hosts | grep $node_alias)" ] ;then
    sudo sed -i "/$node_group/a\ $node_alias ansible_ssh_host=$node_ip" /etc/ansible/hosts
    echo "$node_alias has been added in Ansible hosts."
  else
    echo "$node_alias already exists in Ansible hosts."
  fi
done
node=$(ansible -m ping all | grep UNREACHABLE | awk '{print $1}')
echo "Nodes below are UNREACHABLE:"
echo "$node"
num=$(ansible -m ping all | grep SUCCESS | wc -l)
echo "$num nodes are currently connected to Ansible."
