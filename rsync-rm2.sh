#!/bin/bash
#
# rsync-rm2.sh
#
# rsync backup remarkable2 to specified local directory
#
# uses crontab to run every 15 minutes
#  m h  dom mon dow   command
#  0,15,30,45 * * * * cd /home/apomeroy; /home/apomeroy/rsync-rm2.sh
#
# v1.1 2025/10/24
# - added log file handling
# v1.0 2025/09/26
# - initial version
#

rm2addr="10.11.99.1"
rm2user="root"
localbudir="reBackup-20250926"
netifname="usbnet0"
verbose="true"
logfile="/home/apomeroy/rsync.log"

# look for network interface - will only show up 
# when rm2 is connected via usb c cable

#6: usbnet0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 1000
#    link/ether 7a:e0:7b:14:5b:fc brd ff:ff:ff:ff:ff:ff
#    altname enp10s0u4u1c2
#    altname ens192u4u1c2
#    altname enx7ae07b145bfc
#    inet 10.11.99.14/24 brd 10.11.99.255 scope global noprefixroute usbnet0
#       valid_lft forever preferred_lft forever
#    inet6 fe80::79f6:2665:d6a6:5b50/64 scope link noprefixroute 
#       valid_lft forever preferred_lft forever

echo "starting sync attempt at `date`" > ${logfile}

ip addr show dev ${netifname} > /dev/null 2>&1
if [ $? -eq 0 ]; then
  # interface found
  if [ ${verbose} == 'true' ]; then
    echo "interface ${netifname} found" >> ${logfile}
  fi
  ping -c 1 ${rm2addr} > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    # remarkable2 is reachable
    if [ ${verbose} == 'true' ]; then
      echo "remarkable reachable on ${rm2addr}" >> ${logfile}
    fi

    # confirm backup directory exists
    if [ ! -d ${localbudir} ]; then
      # directory does not exist, try to create
      mkdir ${localbudir} >/dev/null 2>&1
      if [ $? -ne 0 ]; then
        echo "error: local backup directory ${localbudir} does not exist and cannot be created" >> ${logfile}
	exit 1
      fi
    fi

    # run rsync backup
    rsync -avz --progress --delete ${rm2user}@${rm2addr}:/home/root/.local/share/remarkable/xochitl/ ~/${localbudir}/  >> ${logfile} 2>&1
    # rsync ran so move log file to successful
    mv ${logfile} ${logfile}.successful
  else
    # interface is up but rm2 not reachable
    echo "remarkable not reachable on ${rm2addr}" >> ${logfile}
    exit 1
  fi
else
  # interface does not exist
  echo "interface ${netifname} not found" >> ${logfile}
  exit 1
fi
