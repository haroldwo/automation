#!/usr/bin/expect
set account [lindex $argv 0]
set ip [lindex $argv 1]
set account_a [lindex $argv 2]
set pass_a [lindex $argv 3]
set timeout 10;
spawn ssh $account@$ip;
expect *assword:*
send "var\r"
expect {
"*#" { send "useradd $account_a\r" }
"*denied*" { break }
}
expect *#
send "echo ''$pass_a'' | passwd $account_a --stdin\r"
expect *#
send "echo ''$account_a' ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers\r"
expect *#
send "systemctl restart sshd\r"
expect *#
send "exit\r"
expect eof
