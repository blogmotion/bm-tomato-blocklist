#!/bin/sh
###########################################
# Parse une liste d'IP/subnet pour les injecter en blocklist iptables
###########################################
#
# auteur 	    : Mr Xhark (blogmotion.fr)
# How-to        : https://blogmotion.fr/systeme/tomato-bloquer-ip-externes-shodan-21534
# licence type	: Creative Commons Attribution-NoDerivatives 4.0 (International)
# licence info	: http://creativecommons.org/licenses/by-nd/4.0/
#
###########################################
VERSION="2025.12.01"

# Path to *.list files (usb key mount point or /jffs)
DIR_LISTS="/tmp/mnt/CLEUSB/scripts/iptables/block_shodan_censys"

########## DO NOT MODIFY ANYTHING AFTER THIS LINE 
logecho() {
    level=$1
    message=$2
    script_name=$(basename "$0")

    logger -p "$level" "$script_name - $message"
    echo -e "\t$message"
}

update_ipset() {
    name=$1
    file_path=$2

    echo && logecho "info" "Fetching new IPs from file $file_path"
    
    if [[ ! -f "$file_path" ]]; then
        logecho "err" "File $file_path does not exist." && exit 1
    fi
    logecho "info" "Fetched. Now removing all IPs from \"$name\" ipset"
    
    # Create ipset if not exist (normally done in Administration > Scripts > Init)
    ipset list "$name" &>/dev/null || ipset create "$name" hash:net

    # Empty the ipset
    ipset flush "$name"
    
    while IFS= read -r line <&3; do
        ip_subnet=$(echo "$line" | grep '^\([0-9]\{1,3\}\.\?\)\{4\}')

        if [ ! -z "$ip_subnet" ]; then
	        ipset -! add "$name" "$ip_subnet"
        fi

    done 3< "$file_path"
    echo
}

# Injecting lists (one by line)
update_ipset "shodan" "${DIR_LISTS}/input_ips_for_iptables.list" && exit 0 || exit 1