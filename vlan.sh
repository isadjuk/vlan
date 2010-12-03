#!/bin/bash
# ================================================================================================
#      VLAN Configurator 1.1
#      
#      Copyright 2010 iSadjuk <isadjuk@gmail.com>
#      
#      This program is free software; you can redistribute it and/or modify
#      it under the terms of the GNU General Public License as published by
#      the Free Software Foundation; either version 2 of the License, or
#      (at your option) any later version.
#      
#      This program is distributed in the hope that it will be useful,
#      but WITHOUT ANY WARRANTY; without even the implied warranty of
#      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#      GNU General Public License for more details.
#      
#      You should have received a copy of the GNU General Public License
#      along with this program; if not, write to the Free Software
#      Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#      MA 02110-1301, USA.
# ================================================================================================

echo "|----------------------------------------------------------------------"
echo "| VLAN Configurator 1.1 - Created by iSadjuk"
#echo "|"
#echo "| 1.1 - 2010-06-27 - added gateway option"
#echo "| 1.0 - 2010-06-24 - first version"
echo "|----------------------------------------------------------------------"


# CHECKING number of parameters
if [[ "$#" == "0" ]]; then
	echo "| USAGE: vlan.sh [vlan_id] [ip] [netmask] [gateway] [interface]"
	echo -e "| \t vlan_id \t- VLAN identificator"
	echo -e "| \t ip \t\t- IP address (optional, default: 10.90.90.91)"
	echo -e "| \t netmask \t- network mask (optional, default: 255.0.0.0)"
	echo -e "| \t gateway \t- gateway address (optional, default: 0.0.0.0 - not used)"
	echo -e "| \t interface \t- interface name (optional, default: eth0)"
	echo "|----------------------------------------------------------------------"
	exit
	fi

# CHECKING vlan installed
VCONFIG=$(which vconfig)
if [[ $VCONFIG == "" ]]; then
	echo "| ERROR: VLAN package not installed"
	echo "| - type for Debian/Ubuntu: sudo apt-get install vlan"
	echo "|----------------------------------------------------------------------"
	exit
	fi

# CHECKING root user
if [[ $EUID -ne 0 ]]; then
	echo "| ERROR: This program must be run as root user !"
	echo "|----------------------------------------------------------------------"
	exit
	fi
#==========================================================================================================================================
# PARAMETERS
#==========================================================================================================================================
# 1. main
IFACE="eth0"
IFACE_IP="10.90.90.91"
IFACE_MASK="255.0.0.0"
IFACE_GATEWAY="0.0.0.0"
VLANID="$1"
VLANMOD_STATE=`lsmod | grep '8021q '`
VLANID_LAST="";
if [[ -d "/proc/net/vlan" ]]; then
	VLANID_LAST=`ls /proc/net/vlan | grep "${IFACE}" | awk -F"." '{print $2}'`;
	fi

# 2. additional
if [[ "$#" -ge "2" ]]; then
	IFACE_IP="$2"
	echo "| Using CUSTOM IP: ${IFACE_IP}"
	else
	echo "| Using default IP: ${IFACE_IP}"	
	fi

if [[ "$#" -ge "3" ]]; then
	IFACE_MASK="$3"
	echo "| Using CUSTOM NETMASK: ${IFACE_MASK}"
	else
	echo "| Using default NETMASK: ${IFACE_MASK}"	
	fi

if [[ "$#" -ge "4" ]]; then
	IFACE_GATEWAY="$4"
	echo "| Using CUSTOM GATEWAY: ${IFACE_GATEWAY}"
	#else
	#echo "| Using default GATEWAY: ${IFACE_GATEWAY}"
	fi

if [[ "$#" -ge "5" ]]; then
	IFACE="$5"
	echo "| Using CUSTOM INTERFACE: ${IFACE}"
	else
	echo "| Using default INTERFACE: ${IFACE}"
	fi

#==========================================================================================================================================
# CHECKING parameters
#==========================================================================================================================================
# 1. vlan_id
VLANID_CHK=$(echo "$VLANID" | egrep "^[0-9]{1,4}$")
if [[ $VLANID_CHK == "" ]]; then
	echo "| ERROR! - wrong vlan id: [$VLANID]"
	echo "|----------------------------------------------------------------------"
	exit
	fi

# 2. address ip
IFACE_IP_CHK=$(echo "$IFACE_IP" | egrep "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$")
if [[ $IFACE_IP_CHK == "" ]]; then
	echo "| ERROR! - wrong address ip: [$IFACE_IP]"
	echo "|----------------------------------------------------------------------"
	exit
else
	for MYVAR in ${IFACE_IP_CHK//./ }; do
		if [[ "$MYVAR" -lt "0" ||  "$MYVAR" -gt "255" ]]; then
			echo "| ERROR! - wrong address ip: [$IFACE_IP]"
			echo "|----------------------------------------------------------------------"
			exit		
			fi
		done
	fi

# 3. network mask
IFACE_MASK_CHK=$(echo "$IFACE_MASK" | egrep "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$")
if [[ $IFACE_MASK_CHK == "" ]]; then
	echo "| ERROR! - wrong network mask: [$IFACE_MASK]"
	echo "|----------------------------------------------------------------------"
	exit
else
	for MYVAR in ${IFACE_MASK_CHK//./ }; do
		if [[ "$MYVAR" -lt "0" ||  "$MYVAR" -gt "255" ]]; then
			echo "| ERROR! - wrong network mask: [$IFACE_MASK]"
			echo "|----------------------------------------------------------------------"
			exit		
			fi
		done
	fi

# 4. gateway address
IFACE_GATEWAY_CHK=$(echo "$IFACE_GATEWAY" | egrep "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$")
if [[ $IFACE_GATEWAY_CHK == "" ]]; then
	echo "| ERROR! - wrong gateway address: [$IFACE_GATEWAY]"
	echo "|----------------------------------------------------------------------"
	exit
else
	for MYVAR in ${IFACE_GATEWAY_CHK//./ }; do
		if [[ "$MYVAR" -lt "0" ||  "$MYVAR" -gt "255" ]]; then
			echo "| ERROR! - wrong gateway address: [$IFACE_GATEWAY]"
			echo "|----------------------------------------------------------------------"
			exit		
			fi
		done
	fi

# 5. interface
if [[ ! -d "/proc/sys/net/ipv4/conf/${IFACE}" ]]; then
	echo "| ERROR! - wrong interface name: [$IFACE]"
	echo "|----------------------------------------------------------------------"
	exit
	fi
#==========================================================================================================================================
# EXECUTING commands
#==========================================================================================================================================
# LOAD VLAN MODULE 8021q - if not loaded
if [[ "$VLANMOD_STATE" == "" ]]; then
	modprobe 8021q
	echo "| VLAN module 8021q loaded"
	fi

# REMOVE last vlan config
if [[ "$VLANID_LAST" != "" ]]; then
	ifconfig ${IFACE}.${VLANID_LAST} 0.0.0.0 down
	vconfig rem ${IFACE}.${VLANID_LAST} > /dev/null
	echo "| REMOVING VLAN previous interface: ${IFACE}.${VLANID_LAST}"
	
	# not nessesary - this is automatic removing on interface reset
	#IFACE_GATEWAY_LAST=`route -n | grep "UG" | grep "${IFACE}.${VLANID_LAST}" | awk -F" " '{print $2}'`
	#if [[ $IFACE_GATEWAY_LAST != "" ]]; then
	#	route del default gw ${IFACE_GATEWAY_LAST} ${IFACE}.${VLANID_LAST}
	#	echo "| REMOVING previous interface gateway: [${IFACE_GATEWAY_LAST}]"
	#	fi
	sleep 1
	fi

#==========================================================================================================================================
echo "| SETTING VLAN [${IFACE}] with [${VLANID}] ${IFACE_IP}/${IFACE_MASK} ... DONE"
vconfig add $IFACE $VLANID > /dev/null
ifconfig ${IFACE}.${VLANID} ${IFACE_IP} netmask ${IFACE_MASK} up

if [[ $IFACE_GATEWAY != "0.0.0.0" ]]; then
	route add default gw ${IFACE_GATEWAY} ${IFACE}.${VLANID} > /dev/null 2>&1
	
	IFACE_GATEWAY_CHK=`route -n | grep "UG" | grep "${IFACE}.${VLANID}" | awk -F" " '{print $2}'`
	if [[ $IFACE_GATEWAY_CHK == "" ]]; then
		echo "| WARNING! - selected gateway NOT added: [${IFACE_GATEWAY}]"
	else
		echo "| ADDING to interface [${IFACE}.${VLANID}] GATEWAY address: ${IFACE_GATEWAY} ... DONE"
		fi
	fi

echo "|----------------------------------------------------------------------"
#==========================================================================================================================================
