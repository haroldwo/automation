#!/bin/bash
root_pass=$1
ansible_account=$2
ansible_pass=$3
for((i=1;i<=$(cat nodeInfo | wc -l);i++));
do
  node_alias=$(awk "NR==$i{print \$1}" nodeInfo);
  node_ip=$(awk "NR==$i{print \$2}" nodeInfo);
  node_group=$(awk "NR==$i{print \$3}" nodeInfo);
  sed -i "s#var#$root_pass#g" expect_ssh1.sh;
  expect -f expect_ssh1.sh root $node_ip $ansible_account $ansible_pass;
  expect -f expect_scp.sh $ansible_account $node_ip $ansible_pass;
  expect -f expect_ssh2.sh $ansible_account $node_ip $ansible_pass;
  sed -i "s#$root_pass#var#g" expect_ssh1.sh;
  if [ ! -n "$(cat /etc/ansible/hosts | grep $node_group)" ] ;then
    sed -i "/uncatalogued/a\ $node_alias ansible_ssh_host=$node_ip" /etc/ansible/hosts
  else
    if [ ! -n "$(cat /etc/ansible/hosts | grep $node_alias)" ] ;then
      sed -i "/$node_group/a\ $node_alias ansible_ssh_host=$node_ip" /etc/ansible/hosts
    else
      echo "$node_alias has aleady been added in Ansible hosts"
    fi
  fi
done
node=$(ansible -m ping all | grep UNREACHABLE | awk '{print $1}')
echo "Below nodes are still UNREACHABLE!"
echo "$node"
echo " "
num=$(ansible -m ping all | grep SUCCESS | wc -l)
echo "$num nodes are connected to Ansible."
