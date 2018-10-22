#!/bin/bash
yum -y install epel-release
yum -y install koan
koan --server=cobbler.mydomain.org --display --system=name
koan --server=cobbler.mydomain.org --replace-self --system=name
reboot
