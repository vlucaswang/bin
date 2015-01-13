#/bin/bash

file="x86.csv"
#file="x86test.csv"
dest="/etc/comment.txt"

for i in `awk -F ';' '{print $2}' $file`
do
if ping -c 1 $i &> /dev/null
then
CM=`grep $i $file`
IFS_OLD=$IFS
IFS=";"
PARA=($CM)
ssh -o ConnectTimeout=3 $i bash -c "'
cat << EOF > $dest
#SCRCU Production Server
HOSTNAME=${PARA[0]}
IP1=${PARA[1]}
IP2=${PARA[2]}
IP3=${PARA[3]}
应用1=${PARA[4]}
应用2=${PARA[5]}
管理员=${PARA[6]}
序列号=${PARA[7]}
位置=${PARA[8]}
机柜=${PARA[9]}
EOF
'"
IFS=$IFS_OLD
fi
done

exit 0
