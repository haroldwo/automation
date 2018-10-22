#!/bin/bash
wget https://bintray.com/rabbitmq/rpm/download_file?file_path=erlang/21/el/7/x86_64/erlang-21.1-1.el7.centos.x86_64.rpm
mv download* erlang-21.1-1.el7.centos.x86_64.rpm
rpm -Uvh erlang-21.1-1.el7.centos.x86_64.rpm --force
sudo bash -c 'cat <<EOF > /etc/yum.repos.d/rabbitmq.repo
[bintray-rabbitmq-server]
name=bintray-rabbitmq-rpm
baseurl=https://dl.bintray.com/rabbitmq/rpm/rabbitmq-server/v3.7.x/el/7/
gpgcheck=0
repo_gpgcheck=0
enabled=1
EOF'
sudo yum -y install rabbitmq-server
for port in 4369 5671 5672 25672 35672-35682 15672 61613 61614 1883 8883 15674 15675;do
  sudo firewall-cmd --add-port=$port/tcp
done
sudo firewall-cmd --runtime-to-permanent
mkdir /etc/systemd/system/rabbitmq-server.service.d
sudo bash -c 'cat <<EOF > /etc/systemd/system/rabbitmq-server.service.d/limits.conf
[Service]
LimitNOFILE=300000
EOF'
sudo systemctl enable rabbitmq-server &&
sudo systemctl restart rabbitmq-server
rabbitmq-plugins enable rabbitmq_management
version=$(sudo rabbitmqctl status | grep 'RabbitMQ' | awk -F '"' '{print $4}')
sudo wget https://raw.githubusercontent.com/rabbitmq/rabbitmq-management/v$version/bin/rabbitmqadmin -P /usr/local/bin
sudo chmod a+x /usr/local/bin/rabbitmqadmin
sudo sh -c '/usr/local/bin/rabbitmqadmin --bash-completion > /etc/bash_completion.d/rabbitmqadmin'

rabbitmq-server -detached
rabbitmqctl stop_app
rabbitmqctl join_cluster rabbit@rabbit1
rabbitmqctl start_app

rabbitmq-plugins enable rabbitmq_federation
rabbitmq-plugins enable rabbitmq_federation_management
rabbitmqctl set_parameter federation-upstream my-upstream \
'{"uri":"amqp://server-name","expires":3600000}'
rabbitmqctl set_policy --apply-to exchanges federate-me "^amq\." \
'{"federation-upstream-set":"all"}'

rabbitmqctl list_queues
sudo rabbitmqctl list_queues name messages_ready messages_unacknowledged
sudo rabbitmqctl list_exchanges
rabbitmqctl list_bindings
rabbitmqctl environment
rabbitmqctl encode '<<"guest">>' mypassphrase

# allow for at least 65536 file descriptors for user rabbitmq in production environments.
# 4096 should be sufficient for most development workloads.
# https://github.com/rabbitmq/rabbitmq-server/blob/master/docs/advanced.config.example
# another choice for rabbitmqadmin wget 172.16.0.10:15672/cli/rabbitmqadmin
