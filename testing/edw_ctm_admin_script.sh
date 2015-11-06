#!/bin/sh

start()
{

  echo "`date` start begin" >> /root/bmcscripts/start.sh.log
  # Start Control-M EM CORBA Naming Service
  echo "`date` Start Control-M EM CORBA Naming Service" >> /root/bmcscripts/start.sh.log
  su - emuser -c /app/emuser/bin/start_ns_daemon
  sleep 5
  # Start Control-M Configuration Server
  echo "`date` Start Control-M Configuration Server" >> /root/bmcscripts/start.sh.log
  su - emuser -c "/app/emuser/bin/em cms -all &"
  sleep 10
  # Start the Control-M/EM Configuration Agent and the Control-M/EM Server components
  echo "`date` Start the Control-M/EM Configuration Agent and the Control-M/EM Server components" >> /root/bmcscripts/start.sh.log
  su - emuser -c /app/emuser/bin/start_config_agent
  sleep 5
  # Start Control-M/Server Configuration Agent
  echo "`date` Start Control-M/Server Configuration Agent" >> /root/bmcscripts/start.sh.log
  su - ctmuser -c "/app/ctmuser/ctm_server/scripts/start_ca"
  sleep 10
  # Start Control-M/Server
  echo "`date` Start Control-M/Server" >> /root/bmcscripts/start.sh.log
  su - ctmuser -c "/app/ctmuser/ctm_server/scripts/start_ctm"
  sleep 60
  # Start control-m agent
  echo "`date` Start control-m agent" >> /root/bmcscripts/start.sh.log
  su - ctmuser -c "/app/ctmuser/ctm_agent/ctm/scripts/start-ag -u ctmuser -p ALL"
  sleep 10
  echo "`date` start end" >> /root/bmcscripts/start.sh.log
}

stop()
{

  echo "`date` stop begin" >> /root/bmcscripts/stop.sh.log
  #解密密文获取emuser的密码
  TMP_USER=`su - ctmuser -c "perl /app/schscripts/script/mgr/decrypt.pl /app/schscripts/etc/emuser_logon"`
  #截取密码
  EM_PASSWD=`echo $TMP_USER|cut -d':' -f2|cut -d',' -f2`
  #Stop control-m agent
  echo "`date` Stop control-m agent" >> /root/bmcscripts/stop.sh.log
  su - ctmuser -c "/app/ctmuser/ctm_agent/ctm/scripts/shut-ag -u ctmuser -p ALL"
  sleep 10
  #Stop Control-M/Server Configuration Agent
  echo "`date` Stop Control-M/Server Configuration Agent" >> /root/bmcscripts/stop.sh.log
  su - ctmuser -c "/app/ctmuser/ctm_server/scripts/shut_ca"
  sleep 10
  #Stop Control-M/Server
  echo "`date` Stop Control-M/Server" >> /root/bmcscripts/stop.sh.log
  su - ctmuser -c "/app/ctmuser/ctm_server/scripts/shut_ctm"
  sleep 10
  # Stop the Control-M/EM Configuration Agent and all components
  echo "`date` Stop the Control-M/EM Configuration Agent and all components" >> /root/bmcscripts/stop.sh.log
  su - emuser -c "/app/emuser/bin/em ctl -U emuser -P $EM_PASSWD -C Config_Agent -all -cmd shutdown"
  sleep 10
  # Stop the Control-M EM GUI Server
  echo "`date` Stop the Control-M EM GUI Server" >> /root/bmcscripts/stop.sh.log
  su - emuser -c "/app/emuser/bin/em ctl -U emuser -P $EM_PASSWD -C GUI_Server -all -cmd shutdown"
  sleep 5
  # Stop Control-M Configuration Server
  echo "`date` Stop Control-M Configuration Server" >> /root/bmcscripts/stop.sh.log
  su - emuser -c "/app/emuser/bin/em ctl -U emuser -P $EM_PASSWD -C CMS -all -cmd stop"
  sleep 5
  # Stop Control-M EM CORBA Naming Service
  echo "`date` Stop Control-M EM CORBA Naming Service" >> /root/bmcscripts/stop.sh.log
  su - emuser -c "/app/emuser/bin/orbadmin ns stop -local"
  sleep 5
  #sleep 60
  echo "`date` stop end" >> /root/bmcscripts/stop.sh.log
}

status()
{

  echo "`date` check begin" >> /root/bmcscripts/check_ctm.sh.log
  
  ps -u ctmuser -o args | more > /tmp/ctmcheck
  ps -u emuser -o args | more > /tmp/emcheck
  
  ctm_ca=`sed -n '/p_ctmca/p' /tmp/ctmcheck`
  ctm_rt=`sed -n '/p_ctmrt/p' /tmp/ctmcheck`
  ctm_su=`sed -n '/p_ctmsu/p' /tmp/ctmcheck`
  ctm_ns=`sed -n '/p_ctmns/p' /tmp/ctmcheck`
  ctm_wd=`sed -n '/p_ctmwd/p' /tmp/ctmcheck`
  ctm_tr=`sed -n '/p_ctmtr/p' /tmp/ctmcheck`
  ctm_ag=`sed -n '/p_ctmag/p' /tmp/ctmcheck`
  ctm_at=`sed -n '/p_ctmat/p' /tmp/ctmcheck`
  ctm_atw=`sed -n '/p_ctmatw/p' /tmp/ctmcheck`
  ctm_JRE=`sed -n '/ctm_server\/JRE/p' /tmp/ctmcheck`

  em_ns=`sed -n '/Naming_Service/p' /tmp/emcheck`
  em_cms=`sed -n '/\/em cms /p' /tmp/emcheck`
  em_cmsg=`sed -n '/\/em cmsg/p' /tmp/emcheck`
  em_gtw=`sed -n '/\/em gtw/p' /tmp/emcheck`
  em_gcsrv=`sed -n '/\/em gcsrv/p' /tmp/emcheck`
  em_guisrv=`sed -n '/\/em guisrv/p' /tmp/emcheck`
  em_JRE=`sed -n '/ctm_em\/JRE/p' /tmp/emcheck`

  rm -f /tmp/emcheck
  rm -f /tmp/ctmcheck
  
  if [ "$ctm_ca" != "" ] && [ "$ctm_rt" != "" ] && [ "$ctm_su" != "" ] && [ "$ctm_ns" != "" ] && [ "$ctm_wd" != "" ] && [ "$ctm_tr" != "" ] && [ "$ctm_ag" != "" ] && [ "$ctm_at" != "" ] && [ "$ctm_atw" != "" ] && [ "$em_ns" != "" ] && [ "$em_cms" != "" ] && [ "$em_cmsg" != "" ] && [ "$em_gtw" != "" ] && [ "$em_gcsrv" != "" ] && [ "$em_guisrv" != "" ] && [ "$em_JRE" != "" ] ; then
    echo "ALL Control-M service is started!"
    echo "`date` check end" >> /root/bmcscripts/check_ctm.sh.log
    return 0
  elif [ "$ctm_ca" = "" ] && [ "$ctm_rt" = "" ] && [ "$ctm_su" = "" ] && [ "$ctm_ns" = "" ] && [ "$ctm_wd" = "" ] && [ "$ctm_tr" = "" ] && [ "$ctm_ag" = "" ] && [ "$ctm_at" = "" ] && [ "$ctm_atw" = "" ] && [ "$em_ns" = "" ] && [ "$em_cms" = "" ] && [ "$em_cmsg" = "" ] && [ "$em_gtw" = "" ] && [ "$em_gcsrv" = "" ] && [ "$em_guisrv" = "" ] && [ "$em_JRE" = "" ] ; then
    echo "ALL Control-M service is stoped!"
    echo "`date` check end" >> /root/bmcscripts/check_ctm.sh.log
    return 1
  else
    echo $ctm_ca |tee -a /root/bmcscripts/check_ctm.sh.log
    echo $ctm_rt |tee -a /root/bmcscripts/check_ctm.sh.log
    echo $ctm_su |tee -a /root/bmcscripts/check_ctm.sh.log
    echo $ctm_ns |tee -a /root/bmcscripts/check_ctm.sh.log
    echo $ctm_wd |tee -a /root/bmcscripts/check_ctm.sh.log
    echo $ctm_tr |tee -a /root/bmcscripts/check_ctm.sh.log
    echo $ctm_ag |tee -a /root/bmcscripts/check_ctm.sh.log
    echo $ctm_at |tee -a /root/bmcscripts/check_ctm.sh.log
    echo $ctm_atw |tee -a /root/bmcscripts/check_ctm.sh.log
    echo $ctm_JRE |tee -a /root/bmcscripts/check_ctm.sh.log
    echo $em_ns |tee -a /root/bmcscripts/check_ctm.sh.log
    echo $em_cms |tee -a /root/bmcscripts/check_ctm.sh.log
    echo $em_cmsg |tee -a /root/bmcscripts/check_ctm.sh.log
    echo $em_gtw |tee -a /root/bmcscripts/check_ctm.sh.log
    echo $em_gcsrv |tee -a /root/bmcscripts/check_ctm.sh.log
    echo $em_guisrv |tee -a /root/bmcscripts/check_ctm.sh.log
    echo $em_JRE |tee -a /root/bmcscripts/check_ctm.sh.log
    echo "Control-M service is starting or stopping!" |tee -a /root/bmcscripts/check_ctm.sh.log
    echo "`date` check end" >> /root/bmcscripts/check_ctm.sh.log
    return 2
  fi
}

case "$1" in
start)
  start
  exit $?
  ;;
stop)
  stopcount=0
  stop
  status
  ret=$?
  if [ "$ret" != "1" ] ; then
    stop
    status
    if [ "$ret" != "1" ] ; then
      echo "`date` Forced kill Control-M related processes" >> /root/bmcscripts/stop.sh.log
      ps -ef|grep /app/|grep -i -E"emuser|ctmuser"|cut -c 9-15|xargs kill -9
      echo "`date` Delete pid file" >> /root/bmcscripts/stop.sh.log
      rm -f /app/ctmuser/ctm_server/pid/*
      echo "`date` init_prflag" >> /root/bmcscripts/stop.sh.log
      su - ctmuser -c "/app/ctmuser/ctm_server/scripts/init_prflag"
      exit 0
    else
      exit 0
    fi
  else
    exit 0
  fi
;;
status)
  status
  exit $?
;;
restart|reload)
  stop
  start
;;
*)
echo "Usage: $0 {start|stop|reload|restart|status}"
exit 1
;;
esac
exit 0