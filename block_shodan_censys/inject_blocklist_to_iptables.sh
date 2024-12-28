#!/bin/sh
###########################################
# Parse une liste d'IP/subnet pour les injecter en blocklist iptables
###########################################
#
# auteur 	: Mr Xhark (blogmotion.fr)
# licence type	: Creative Commons Attribution-NoDerivatives 4.0 (International)
# licence info	: http://creativecommons.org/licenses/by-nd/4.0/
VERSION="2024.12.28"


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

    echo
    logecho "info" "Fetching new IPs from file $file_path"
    
    if [[ ! -f "$file_path" ]]; then
        logecho "err" "File $file_path does not exist." && exit 1
    fi
    
    # Creation du set si manquant (normalement fait dans Administration > Scripts > Init)
    ipset list "$name" &>/dev/null || ipset create "$name" hash:net

    logecho "info" "Fetched. Now removing all IPs from \"$name\" ipset"

    ipset flush "$name"
    
    while IFS= read -r line <&3; do
        match=$(echo "$line" | grep '^\([0-9]\{1,3\}\.\?\)\{4\}')

        if [ ! -z "$match" ]; then
	        ipset -! add "$name" "$match"
        fi

    done 3< "$file_path"
    echo
}


# debut du script
update_ipset "shodan" "/tmp/mnt/CLEUSB/scripts/iptables/block_shodan_censys/input_ips_for_iptables.list" && exit 0 || exit 1
