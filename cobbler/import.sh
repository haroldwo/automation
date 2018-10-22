download ISO
manually create a file involving ISO name and cobbler ISO name such as "~/CentOS-7-x86_64-DVD-1708.iso CentOS-7-x86_64" with multi line.

#!/bin/bash
isoList=./ISOs
maxLine=$(cat $isoList | wc -l)
for ((line = 1; $line <= $maxLine; line++)); do
  isoName=$(head -n $line $isoList | awk '{print $1}');
  cobblerISO=$(head -n $line $isoList | awk '{print $2}');
  mkdir /mnt/$cobblerISO
  mount -t iso9660 -o loop,ro $isoName /mnt/$cobblerISO;
  cobbler import --name=$cobblerISO --path=/mnt/$cobblerISO;
done
cobbler distro list
