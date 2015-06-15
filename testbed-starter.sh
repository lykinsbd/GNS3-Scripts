#!/usr/bin/env bash

#
# This script automates launching a GNS 3 lab, VMware Fusion
# Lab test box and IOU server, and linking all of the NICs together to 
# utilize the network/internet connection on the Mac
#

# Topology file located in GNS3/Projects directory
TOPFILE="$HOME/GNS3/Projects/Testbed/Testbed.gns3"

# VMWare Fusion IOU-VM location
LABVM="$HOME/Documents/Virtual Machines.localized/GNS3 IOU VM_1.3.2.vmwarevm"

# tap0 interface IP configuration
TAP0IP="10.1.1.1/24"




#### Start Opening Things Up ####

# Open VMware Fusion with IOU VM
printf "\n=====[ Opening VMWare Fusion Lab box  ]=====\n\n"
/Applications/VMware\ Fusion.app/Contents/Library/vmrun -T Fusion start "$LABVM" nogui &
# To suspend: /Applications/VMware\ Fusion.app/Contents/Library/vmrun -T Fusion suspend "$LABVM"


# Open GNS3 with topology file
printf "\n=====[ Opening GNS3  ]=====\n\n"
/Applications/GNS3.app/Contents/MacOS/GNS3 "$TOPFILE" &



# Number of seconds to wait before assigning IP configuration to tap0
# This lets GNS3 start and bring up the tun interfaces
printf "\n=====[ Waiting 20 seconds for GNS3 and VMWare Fusion to start and bring up lab  ]=====\n"
for i in {20..1};do printf "$i, " && sleep 1 ;done


printf "\n=====[ Setting up Tunnel interfaces for lab  ]=====\n\n"
# Set the IP configuration for the the tap interfaces and turn them up
sudo ifconfig tap0 $TAP0IP up
sudo ifconfig tap1 up
printf "sudo ifconfig tap0 $TAP0IP up\n"
printf "sudo ifconfig tap1 up\n"
printf "Tunnel Interfaces configured.\n" 
sleep 2

printf "=====[ Setting up Virtual Forwarding ]=====\n\n"
# Turn on routing for virtual interface on MAC
# This step is needed if the result of `sysctl -a | grep ip.forwarding` = 0
# sudo sysctl -w net.inet.ip.forwarding=1
# One way to parse this info:
# IPFORWARDING="$(sysctl -a | grep ip.forwarding | sed -n 's/net.inet.ip.forwarding: //p')"
# Shorter way:
IPFORWARDING="$(sysctl -a | grep ip.forwarding)"
IPFORVALUE="$(sysctl -a | grep ip.forwarding | tail -c 2)"

if [ "$IPFORVALUE" -eq "0" ]
	then
		sudo sysctl -w net.inet.ip.forwarding=1
		printf "\nsudo sysctl -w net.inet.ip.forwarding=1\n" 
		printf "IP Forwarding is now configured.\n\n"
	else
		printf "\n$IPFORWARDING\n"
		printf "IP Forwarding was already set.\n\n"
fi
sleep 2

printf "=====[ Setting up routing to lab ]=====\n\n"
# Turn on routing to internal networks in lab
# This step is needed if the result of `netstat -rn | grep 172.16.195`
# doesn't give a route to the internal networks (10.1.2.0/24 and 10.1.3.0/24)
# sudo route -nv add -net 10.1.2.0/23 10.1.1.2
LABROUTING="$(netstat -rn | grep "10.1.2/23")"

if [ -z "$LABROUTING" ]
	then
		sudo route -nv add -net 10.1.2.0/23 10.1.1.2
		printf "\nsudo route -nv add -net 10.1.2.0/23 10.1.1.2\n"
		printf "Route to lab network has been added.\n\n"
	else
		printf "\n$LABROUTING\n"
		printf "Route to lab network was already in place.\n\n"
fi
sleep 2


printf "=====[ Choosing default interface ]=====\n\n"
# Verify which NIC is being used for internet access WIRED or WIRELESS (EN0 or EN1)
# netstat -rn | grep default
# DEFAULTROUTE="$(netstat -rn | grep default)"

printf "\nnetstat -rn | grep default | tail -c 4\n"
# printf "$DEFAULTROUTE\n\n"
# printf "Please enter the inteface name that is currently the default route.\n"
# printf "Note: Please type the name exactly as it appears in the above output.\n"
# printf "> "
# read DEFAULTINTERFACE
DEFAULTINTERFACE="$(netstat -rn | grep default | tail -c 4)"
printf "\nDefault interface set to $DEFAULTINTERFACE\n\n"
sleep 2

printf "=====[ Setting up NATing to the lab network  ]=====\n\n"
# Turn on NATing for the tun0 interface from our main interface eth0
# This step is needed if there is no output for:
# `ps aux | grep natd | grep en0`  - WIRED
# or
# `ps aux | grep natd | grep en1`  - WIRELESS
# sudo natd -interface en0 -use_sockets -same_ports -unregistered_only -dynamic -clamp_mss
# sudo natd -interface en1 -use_sockets -same_ports -unregistered_only -dynamic -clamp_mss
NATTING="$(ps aux | grep natd | grep $DEFAULTINTERFACE)"

if [ -z "$NATTING" ]
	then
		sudo natd -interface $DEFAULTINTERFACE -use_sockets -same_ports -unregistered_only -dynamic -clamp_mss
		printf "\nsudo natd -interface $DEFAULTINTERFACE -use_sockets -same_ports -unregistered_only -dynamic -clamp_mss\n"
		printf "Natting is now configured.\n\n"
	else
		printf "\n$NATTING\n"
		printf "Natting was already configured.\n\n"
fi	


printf "=====[ Turning on Firewall  ]=====\n\n"
# Turn on Firewall
# This step is needed if result of `sysctl -a | grep ip.fw.en` = 0
# sudo sysctl -w net.inet.ip.fw.enable=1
FIREWALL="$(sysctl -a | grep ip.fw.en)"
FIREWALLVALUE="$(sysctl -a | grep ip.fw.en | tail -c 2)"

if [ "$FIREWALLVALUE" -eq "0" ]
    then
        sudo sysctl -w net.inet.ip.fw.enable=1
        printf "\nsudo sysctl -w net.inet.ip.fw.enable=1\n" 
        printf "IP Firewall is now configured.\n\n"
	else
        printf "\n$FIREWALL\n"
        printf "IP Firewall was already set.\n\n"
fi


printf "=====[ Adding NAT rules to firewall  ]=====\n\n"
# Add rules to firewall:
# Verify rules: `sudo ipfw show`
# WIRED:
# sudo ipfw add divert natd ip from any to any via en0
# WIRELESS:
# sudo ipfw add divert natd ip from any to any via en1

FWALLRULES="$(sudo ipfw show | grep $DEFAULTINTERFACE)"

if [ -z "$FWALLRULES" ]
    then
        sudo ipfw add divert natd ip from any to any via $DEFAULTINTERFACE
		printf "\nsudo ipfw add divert natd ip from any to any via $DEFAULTINTERFACE\n"
		printf "Firewall rules are now configured.\n\n"
    else
        printf "\n$FWALLRULES\n"
        printf "Firewall rules were already configured.\n\n"
fi


printf "=====[ Creating Bridge interface from Lab to VMWare  ]=====\n\n"
# Create brige to VM if needed
# sudo ifconfig bridge1 create
# sudo ifconfig vmnet3 down
# sudo ifconfig vmnet3 inet delete
# sudo ifconfig bridge1 addm vmnet3
# sudo ifconfig bridge1 addm tap1
# sudo ifconfig bridge1 up

BRIDGE1="$(ifconfig bridge1 | grep "does not exist")"

if [ -z "$BRIDGE1" ]
	then
        sudo ifconfig vmnet3 down
        sudo ifconfig vmnet3 inet delete
        sudo ifconfig bridge1 addm vmnet3
        sudo ifconfig bridge1 addm tap1
        sudo ifconfig bridge1 up
        printf "\nBridge1 already exists adding interfaces vmnet3 and tap1\n\n"
	else
        sudo ifconfig vmnet3 down
        sudo ifconfig vmnet3 inet delete
	    sudo ifconfig bridge1 create
		sudo ifconfig bridge1 addm vmnet3
        sudo ifconfig bridge1 addm tap1
        sudo ifconfig bridge1 up
		printf "\nBridge1 Created from vmnet3 and tap1\n\n"

fi

exit
