#!/bin/bash
# Name    : openconnect-up.sh
# Purpose : A wrapper to connect to a AnyConnect based VPN-Gatway using openconnect
# Author  : one7two99
# Version : 1.0
# Date    : 11/28/2034
# Github  : https://github.com/one7two99/qubes-split-openconnect
# Inspired by: https://github.com/sorinipate/vpn-up-for-openconnect/blob/main/vpn-up.command
#              Author    : Sorin-Doru Ipate
#              Edited by : Mohammad Amin Dadgar
#              Copyright : Sorin-Doru Ipate

### Location of log files
PID_FILE_PATH="${PWD}/${PROGRAM_NAME}.pid"
LOG_FILE_PATH="${PWD}/${PROGRAM_NAME}.log"

### Declaration for the VPN connections
export VPN_NAME="<VPN.DOMAIN.COM>"
export VPN_HOST=<YOUR.VPN.IP.ADDRESS>
export VPN_GROUP=<VPNGROUP>
export VPN_USER=<VPNLOGINNAME>
export SERVER_CERTIFICATE="<SERVER-CERTIFICATE-HASH>"
export PROTOCOL=anyconnect
# The VPN_PASSFILE contains the gpg encrypted VPN password
# Split GPG has to work for this solution as the private key is placed in a Qubes VaultVM
# See https://www.qubes-os.org/doc/split-gpg/ how to setup Split GPG
export VPN_PASSFILE=/rw/config/vpn-password.gpg

### BEGIN of functions
function start(){
    ### Remove the # in case you want to check the internet connection before conneting
    ### This requires that your VPN gateway is pingable! I don't have ping enabled on our VPN gateway
    #    if ! is_network_available
    #        then
    #            printf "Please check your internet connection or try again later!\n"
    #            exit 1
    #    fi

    if is_vpn_running
       then
          printf "Already connected to a VPN!\n"
          exit 1
       else
          printf "Starting $0 ...\n"
          printf "Process ID (PID) stored in $PID_FILE_PATH ...\n"
          printf "Logs file (LOG) stored in $LOG_FILE_PATH ...\n"
          printf "Starting the $VPN_NAME on $VPN_HOST using $PROTOCOL ...\n"
          # replace /etc/resolv.conf with a symbolic link to /run/resolvconf/resolv.con
          mv /etc/resolv.conf /etc/resolv.conf.bak
          ln -s /run/resolvconf/resolv.conf /etc/resolv.conf
          # connect to the vpn via openconnect
          echo `qubes-gpg-client -d $VPN_PASSFILE 2>/dev/null` | sudo openconnect --protocol=$PROTOCOL \
                                              --background $VPN_HOST \
                                              --user=$VPN_USER \
                                              --authgroup=$VPN_GROUP \
                                              --passwd-on-stdin \
                                              --servercert=$SERVER_CERTIFICATE \
                                              --pid-file $PID_FILE_PATH > $LOG_FILE_PATH 2>&1
          # Check status
          if is_vpn_running
             then
                printf "Connected to $VPN_NAME\n"
                print_current_ip_address
                # add firewall rules for NAT
                # https://github.com/Qubes-Community/Contents/blob/master/docs/configuration/vpn.md
                sleep 3
                iptables -t nat -F PR-QBS
                iptables -t nat -A PR-QBS -i vif+ -p udp --dport 53 -j DNAT --to `cat /etc/resolv.conf | grep "nameserver "| sed -n '1p' | gawk '{print $2}'`
                iptables -t nat -A PR-QBS -i vif+ -p udp --dport 53 -j DNAT --to `cat /etc/resolv.conf | grep "nameserver "| sed -n '2p' | gawk '{print $2}'`
                # Accept traffic to VPN
                iptables -P OUTPUT ACCEPT
                iptables -F OUTPUT
             else
                printf "Failed to connect!\n"
          fi
    fi
}

function stop() {
   if is_vpn_running
      then
         printf "Connected ...\nRemoving $PID_FILE_PATH ...\n"
         local pid=$(cat $PID_FILE_PATH)
         kill -9 $pid > /dev/null 2>&1
         rm -f $PID_FILE_PATH > /dev/null 2>&1
   fi
   printf "Disconnected ...\n"
}

function status() {
   if is_vpn_running
      then
         printf "Connected ...\n"
         print_current_ip_address
      else
         printf "Not connected ...\n"
   fi
}

function is_network_available() {
   # Check if VPN gateway is reachable (requires ping to work)
   ping -q -c 1 -W 1 $VPN_HOST > /dev/null 2>&1;
}

function is_vpn_running() {
   test -f $PID_FILE_PATH && return 0
}

function print_current_ip_address() {
   local ip=$(dig @resolver4.opendns.com myip.opendns.com +short)
   printf "Your current external IP address is $ip ...\n"
}
### END of functions

case "$1" in
   start)
      start
      ;;
   stop)
      stop
      ;;
   status)
      status
      ;;
   restart)
      $0 stop
      $0 start
      ;;
   *)
      printf "Usage: $(basename "$0") (start | stop | status | restart)\n"
      exit 0
      ;;
esac
