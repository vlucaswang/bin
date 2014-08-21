#!/bin/bash

#Manage SCRCU vsftpd conf files
#Provided by Xiaochuan Wang
#xiaochuan.wang@sysssc.com

USERFILE=/etc/vsftpd/virtusers
USERDB=/etc/vsftpd/virtusers.db
CONFBASE=/etc/vsftpd/vconf
TMPCONF=/etc/vsftpd/vconf/vconf.tmp
FTPBASE=/data/rpt
FTPHOST=ftphost
USERNAME=$2
ROOT_UID=0

#Run as root.
if  [ "$EUID" -ne "$ROOT_UID" ];then
        echo "Must be root to run this script."
        exit 87
fi

if [ $# != 3 ];then
        echo "Usage: $0 {create|disable|enable|passwd|delete} {username} {center code}" >&2
        exit 1
fi

function check_username_exist() {
                #Check if virtual user already exist
                USERCOUNT=$(sed -n 'p;n' $USERFILE | grep -w $USERNAME | wc -l)
                if [ $USERCOUNT -ne 0 ];then
                echo "User $USERNAME ALREADY exist!" && exit
                fi
}

check_username_notexist() {
                #Check if virtual user not exist
                USERCOUNT=$(sed -n 'p;n' $USERFILE | grep -w $USERNAME | wc -l)
                if [ $USERCOUNT -eq 0 ];then
                echo "User $USERNAME NOT exist!" && exit
                fi
}

get_password() {
                #Get the password
                echo -n "Input password: "
                read PASSWORD
                #Check if password is empty
                if [ -z "$PASSWORD" ];then
                echo "Empty password!!" && exit
                fi
}

update_userdb() {
                #Delete the virtual user db
                rm -f $USERDB
                #Generate the virtual user db
                db_load -T -t hash -f $USERFILE $USERDB
}

case "$1" in
        'create' )
                check_username_exist
                get_password
                #Write the username and password to $USERFILE
                echo $USERNAME >> $USERFILE
                echo $PASSWORD >> $USERFILE
                update_userdb
                #Create the configure file of virtual user
                cp $TMPCONF $CONFBASE/$USERNAME
                USER1=$(echo | awk '{print substr("'${USERNAME}'",1,2)}')
                USER2=$(echo | awk '{print substr("'${USERNAME}'",3,6)}')
                #Replace the home directory name of virtual user
                sed -i "s/virtuser/$USER1\/$3\/$USER2/g" $CONFBASE/$USERNAME
                #Create the home directory of virtual user
                mkdir $FTPBASE/$USER1/$3/$USER2 -p
                #Change the owner of home directory to OS user $FTPHOST
                chown -R $FTPHOST:$FTPHOST $FTPBASE/$USER1/$3/$USER2
                ;;

        'disable' )
                check_username_notexist
                #Change the owner of home directory from $FTPHOST to root
                chown root:root $FTPBASE/$USER1/$3/$USER2
                #Change the permissions of home directory to read-only for root
                chmod 700 $FTPBASE/$USER1/$3/$USER2
                ;;

        'enable' )
                check_username_notexist
                #Change the owner of home directory from root to $FTPHOST to root
                chown $FTPHOST:$FTPHOST $FTPBASE/$USER1/$3/$USER2
                #Change the permissions of home directory to 775 for $FTPHOST
                chmod 775 $FTPBASE/$USER1/$3/$USER2
                ;;

        'delete' )
                check_username_notexist
                #Get the row numbers of username and password of virtual user
                ROWNUMBER=$(cat -n $USERFILE | sed -n 'p;n' | grep -w $USERNAME | awk '{print $1}' | head -n 1)
                #Delete the username and password of virtual user from $USERFILE
                sed -i "${ROWNUMBER}d" $USERFILE
                sed -i "${ROWNUMBER}d" $USERFILE
                update_userdb
                #Delete the configure file of virtual user
                rm -f $CONFBASE/$USERNAME
                #Rename the home directory name of virtual user
                mv $FTPBASE/$USER1/$3/$USER2 $FTPBASE/$USER1/$3/$USER2.deleted
                ;;

        'passwd' )
                check_username_notexist
                get_password
                #Get the row numbers of username and password of virtual user
                ROWNUMBER=$(cat -n $USERFILE | sed -n 'p;n' | grep -w $USERNAME | awk '{print $1}' | head -n 1)
                PASSWORDNUMBER=$(expr $ROWNUMBER + 1)
                sed -i "${PASSWORDNUMBER}d" $USERFILE
                sed -i "${ROWNUMBER}a $password" $USERFILE
                update_userdb
                ;;
        *)
                echo "Usage: $0 {create|disable|enable|passwd|delete} {username} {center code}" >&2
                exit 1
                ;;
esac

exit 0