#!/usr/bin/expect
set account [lindex $argv 0]
set ip [lindex $argv 1]
set pass [lindex $argv 2]
set timeout 10;
spawn scp /home/$account/.ssh/id_rsa.pub $account@$ip:~;
expect *assword:*
send "$pass\r"
expect *denied*
break
