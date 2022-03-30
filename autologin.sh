#!/bin/bash

# Log in CityU CS Network Captive Portal
#
# Copyright (c) 2017-2022, WAN Hu <hu.wan@my.cityu.edu.hk>
#

# Enter your CityU EID (without "-c") and PASSWORD
EID=foo
PASSWORD=bar

# NOTE: Ubuntu 20.04 or above: SSL routines:ssl_choose_client_version:unsupported protocol
# Solution: https://askubuntu.com/a/1233456. Following are excerpts:
#
# Add to the beginning of /etc/ssl/openssl.cnf:
: '
openssl_conf = default_conf
'
# Add to the end:
: '
[ default_conf ]
ssl_conf = ssl_sect
[ ssl_sect ]
system_default = system_default_sect
[ system_default_sect ]
MinProtocol = TLSv1.2
CipherString = DEFAULT:@SECLEVEL=1
'

# NOTE: --tlsv1 --insecure options are required for cityu cs network captive portal
# NOTE: --data-urlencode option for password containing special characters

display_help()
{
    echo "A bash script to log in CityU CS network captive portal."
    echo
    echo "Syntax: $0 [-h|c|i|o|t]"
    echo "Options:"
    echo "h     Print this help."
    echo "c     Check internet connection and log in network captive portal."
    echo "i     Log in network captive portal."
    echo "o     Log out network captive portal."
    echo "t     Test internet connection."
    echo
}

# URL that returns HTTP response code of 204 (No Content)
# More URLs for detecting captive portals can be found here:
# https://wiki.ding.net/index.php?title=Detecting_captive_portals
URL=http://cp.cloudflare.com/generate_204

NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'

connectivity_state_count=0
try_connect_interval=3 # in second

openssl_check() {
    OS_VERSION=$(lsb_release -rs)
    OS_VERSINFO=$(lsb_release -rs|cut -d . -f 1)
    SSL_CONF=$(grep openssl_conf /etc/ssl/openssl.cnf)
    if [[ $OS_VERSINFO -ge "20" ]]; then
	if [ -z "$SSL_CONF" ]; then
	    echo -e ${YELLOW}WARNING: You need to manually lower SSL security level on Ubuntu $OS_VERSION.${NOCOLOR}
	    echo "Please refer to the comments at the top of this login script for more details."
	fi
    fi
}

# https://superuser.com/a/1659582
connectivity_check() {
    local RESPONSE_CODE
    if command -v curl &> /dev/null
    then
	RESPONSE_CODE=$(curl --silent --max-time 3 --output /dev/null --write-out "%{response_code}" "$URL")
    else
	RESPONSE_CODE=$(wget --spider -S -T 1 -t 1 -4 $URL 2>&1 | grep "HTTP/" | awk '{print $2}')
    fi

    RESPONSE_CODE=${RESPONSE_CODE##+(0)}

    if (( RESPONSE_CODE >= 200 )) && (( RESPONSE_CODE <= 299 )) ; then
	echo -e "Testing Internet status: ${GREEN}You're connected to the Internet.${NOCOLOR}"
    else
	let "connectivity_state_count+=1"
	echo -e "Testing Internet status: ${RED}No Internet access.${NOCOLOR}"
    fi
}

log_in_captive_portal() {
    if [ "$EID" == "foo" ] || [ "$PASSWORD" == "bar" ]; then
	echo -e ${RED}ACTION REQUIRED: Enter your EID and PASSWORD.${NOCOLOR}
	echo "Modify the login script to replace the EID and PASSWORD in the following lines:"
	grep --color=auto -m2 -n -e "EID=" -e "PASSWORD=" $0
	exit
    fi

    openssl_check

    if command -v curl &> /dev/null
    then
	curl --data "username=$EID" --data-urlencode "ctx_pass=$PASSWORD" --data "domain_name=CITYUMD" --data "modify=Secure+Login" --tlsv1 --insecure --silent --output /dev/null 'https://cp.cs.cityu.edu.hk:16979/loginform.html?'
    else
	wget --post-data "username=$EID&ctx_pass=$PASSWORD&domain_name=CITYUMD&modify=Secure+Login" --delete-after --secure-protocol=TLSv1 --no-check-certificate --auth-no-challenge -q -O/dev/null 'https://cp.cs.cityu.edu.hk:16979/loginform.html?'
    fi
}

log_out_captive_portal()
{
    if ! command -v curl &> /dev/null
    then
	echo "Command 'curl' not found, but can be installed with: sudo apt install curl (Ubuntu)"
	exit
    fi

    curl --tlsv1 --insecure --silent --output /dev/null 'http://cp.cs.cityu.edu.hk:16978/logout.html'
}

check_and_login()
{
    for run in {1..3}; do
	connectivity_check
	if [[ "$connectivity_state_count" -gt 0 ]]; then
	    sleeptime=$(( 2*run ))
	    sleep $sleeptime
	else
	    sleep 1
	fi
    done

    if [[ "$connectivity_state_count" -eq 0 ]]; then
	echo -e ${GREEN}You are already logged in.${NOCOLOR}
	exit 0
    else
	echo -e ${RED}No Internet access.${NOCOLOR}
    fi

    for try in {1..3}; do
	log_in_captive_portal
	connectivity_state_count=0
	connectivity_check
	if [[ "$connectivity_state_count" -eq 0 ]]; then
	    echo -e ${GREEN}Log in success.${NOCOLOR}
	    break
	fi
	echo -e ${RED}Log in failed, will try again in $try_connect_interval seconds.${NOCOLOR}
	sleep $try_connect_interval
	try_connect_interval=$(( 2*try_connect_interval ))
    done
}

while getopts ":chiot" option; do
    case $option in
	h) # display Help
	    display_help
	    exit;;
	c) # check connection and log in
	    check_and_login
	    exit;;
	i) # log in
	    log_in_captive_portal
	    check_and_login
	    exit;;
	o) # log out
	    log_out_captive_portal
	    exit;;
	t) # test internet connection
	    connectivity_check
	    exit;;
	\?) # Invalid option
	    echo -e ${RED}Error: Invalid option.${NOCOLOR}
	    display_help
	    exit;;
    esac
done

log_in_captive_portal
check_and_login
