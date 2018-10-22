#!/usr/bin/expect
set account [lindex $argv 0]
set ip [lindex $argv 1]
set pass [lindex $argv 2]
set timeout 10;
spawn ssh $account@$ip;
expect *assword:*
send "$pass\r"
expect {
"*$ " { send "mkdir .ssh\r" }
"*denied*" { break }
}
expect "*$ "
send "chmod 700 .ssh\r"
expect "*$ "
send "cat id_rsa.pub >> ~/.ssh/authorized_keys\r"
expect "*$ "
send "chmod 600 .ssh/authorized_keys\r"
expect "*$ "
send "exit\r"
