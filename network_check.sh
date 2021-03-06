#!/bin/bash
# Author:
# twitter.com/pitto
#
# HOW TO INSTALL:
#
# 1) Install ifupdown and fping with the following command:
# sudo apt-get install ifupdown fping
#
# 2) Then install this script into a folder and add to your crontab -e this row (be sure that the script is also executable):
# */5 * * * * /yourhome/yourname/network_check.sh
#
# Note:
# If you want to perform automatic repair fsck at reboot
# remember to uncomment fsck autorepair here: nano /etc/default/rcS

# Let's check if fping and ipupdown are installed, if not the script will stop running
command -v fping >/dev/null 2>&1 || { echo >&2 "Sorry but fping is not installed. Aborting.";  exit 1; }
command -v ifup >/dev/null 2>&1 || { echo >&2 "Sorry but ifupdown is not installed. Aborting.";  exit 1; }

# Let's clear the screen
clear

# Write here the gateway you want to check to declare network working or not
gateway_ip='www.google.com'

# Write here your Network card name as the name you see in ifconfig
nic='wlan0'

# Here we initialize the check counter to zero
network_check_tries=0

# Here we specify the maximum number of failed checks
network_check_threshold=5

# Set the following variable to true if you want to reboot as a last
# option to fix wifi after network_check_treshold attempts
reboot_server=false

# This function will be called when network_check_tries is equal or greather than network_check_threshold
function restart_wlan {
    # If network test failed more than $network_check_threshold
    echo "Network was not working for the previous $network_check_tries checks."
    # We restart specified Wireless LAN
    echo "Restarting $nic"
    /sbin/ifdown '$nic'
    sleep 5
    /sbin/ifup --force '$nic'
    sleep 60
    host_status=$(fping $gateway_ip)
    if [[ $host_status != *"alive"* ]]; then
        if [ "$reboot_server" = true ] ; then
            echo "Network is not working, rebooting."
            reboot
        fi
    fi
}

# This loop will run network_check_tries times and if we have network_check_threshold failures
# we declare network as not working and we'll restart the wireless card
while [ $network_check_tries -lt $network_check_threshold ]; do
    # We check if ping to gateway is working and perform the ok / ko actions
    host_status=$(fping $gateway_ip)
    # Increase network_check_tries by 1 unit
    network_check_tries=$[$network_check_tries+1]
    # If network is working
    if [[ $host_status == *"alive"* ]]; then
        # We print positive feedback and quit
        echo "Network is working correctly" && exit 0
    else
        # If network is down print negative feedback and continue
        echo "Network is down, failed check number $network_check_tries of $network_check_threshold"
    fi
    # If we hit the threshold we restart wlan
    if [ $network_check_tries -ge $network_check_threshold ]; then
        restart_wlan
    fi
    # Waiting 5 seconds between every check
    sleep 5
done
