#!/usr/bin/env bash
# Ce script permet de convertir une grande list d'IP (venant de fortinet par exemple) vers une liste au format /CIDR
# Auteur: xhark (avec Copilot)
#
# Usage: ./ip_merge_to_cidr.sh shodan_biglist.txt > shodan_cidr.txt

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <fichier_ips>" >&2
    exit 1
fi

infile="$1"

python3 - "$infile" << 'EOF'
import sys
import ipaddress

infile = sys.argv[1]

ips_or_nets = []

with open(infile, "r", encoding="utf-8", errors="ignore") as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith("#"):
            continue

        token = line.split()[0]

        try:
            if "/" not in token:
                # IPv4
                try:
                    ip = ipaddress.IPv4Address(token)
                    ips_or_nets.append(ipaddress.IPv4Network(f"{ip}/32"))
                except ipaddress.AddressValueError:
                    # IPv6
                    ip6 = ipaddress.IPv6Address(token)
                    ips_or_nets.append(ipaddress.IPv6Network(f"{ip6}/128"))
            else:
                # CIDR déjà présent
                net = ipaddress.ip_network(token, strict=False)
                ips_or_nets.append(net)

        except Exception:
            continue

collapsed = ipaddress.collapse_addresses(ips_or_nets)

for net in collapsed:
    print(str(net))
EOF
