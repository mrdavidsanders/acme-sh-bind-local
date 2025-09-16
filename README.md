# Bind9 challenge script for acme.sh
Having found some esoteric and occasionally downright dangerous
`acme.sh` Bind dns challenge implementations floating about the
internet, I wrote this very simple script.

In general it ought to be safe for the vast majority of zone layouts
and will not hose anything if errors occur. 

Vaguely interesting tunable parameters are:
```
BIND_USER="bind"
ZONE_SN_FORMAT="[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]"
ZONE_DIR="/etc/bind/zones"
TMP_DIR="/tmp"
```

You might also want to the check the location of:
- `rndc`
- `named-checkzone`
- `awk`
- `egrep`
- `sed
