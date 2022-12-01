#!/bin/bash

echo "Machine name : $(hostnamectl | grep Static | cut -d' ' -f4)"
echo "OS $(cat /etc/redhat-release | cut -d' ' --fields=1,2,4) and kernel version is $(uname -r)"
echo "IP : $(ip -4 a | grep inet | tail -1 | tr -s ' ' | cut -d' ' -f3 | cut -d'/' -f1)"
echo "RAM : $(free --mega -h | grep Mem: | tr -s ' ' | cut -d' ' -f4) memory available on $(free --mega -h | grep Mem: | tr -s ' ' | cut -d' ' -f2) total memory"
echo "Disk : $(df -h | tr -s ' ' | grep " /$" | cut -d' ' -f4) space left"
echo "Top 5 processes by RAM usage :"
for i in $(seq 1 5)
do
  echo "  - $(ps -o cmd -e --sort=-%mem | head -6 | tail -5  | tr -s ' ' | head -${i} | tail -1)"
done
echo Listening ports :
a="$(ss -lnp4H)"
while read line ;
do
  port_type=$(cut -d' ' -f1 <<< "${line}")
  port_num=$(echo $line | cut -d' ' -f5 | cut -d':' -f2)
  port_service=$(echo $line | tr -s ' ' | cut -d' ' -f7 | cut -d'"' -f2)
  echo "  - ${port_num} ${port_type} ":" ${port_service}"
done <<< "${a}"

cat_pic=$(curl -s https://cataas.com/cat > potichat)
ext=$(file --extension potichat | cut -d' ' -f2 | cut -d'/' -f1)
if [[ ${ext} == "jpeg" ]]
then
  cat_ext="cat.${ext}"
elif [[ ${ext} == "png" ]]
then
  cat_ext="cat.${ext}"
else
  cat_ext="cat.gif"
fi
mv potichat ${cat_ext}
chmod +x ${cat_ext}
echo " "
echo "Here is your random cat : ./${cat_ext}"
