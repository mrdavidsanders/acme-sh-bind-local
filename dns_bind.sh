#!/bin/bash
set -e

# Bind things
# This is more verbose than necessary to make it clear
BIND_USER="bind"
ZONE_SN_FORMAT="[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]"
ZONE_DIR="/etc/bind/zones"
TMP_DIR="/tmp"

function dns_bind_local_add() {
    # ACME things
    CHALLENGE_PREFIX="_acme-challenge"
    CHALLENGE=$1
    KEY=$2
    DOMAIN=$(/bin/echo ${CHALLENGE}|/bin/sed "s/${CHALLENGE_PREFIX}.//")

    # Copy the zone somewhere
    ZONE_FILE="$DOMAIN.zone"
    if [ -f $ZONE_DIR/$ZONE_FILE ]; then
            /bin/cp -p $ZONE_DIR/$ZONE_FILE $TMP_DIR
    else
            echo "${ZONE_FILE} not found in ${ZONE_DIR}"
            exit 1
    fi

    # Bump the serial number - should work for the vast majority of
    # zone layouts, but YMMV (especially if you use tildes)
    SERIAL=$(/bin/cat $TMP_DIR/$ZONE_FILE | \
    /usr/bin/tr '\n' '`' | \
    /usr/bin/egrep -o '^.*SOA.*\(.*\)' | \
    /usr/bin/egrep -o "${ZONE_SN_FORMAT}")
    /bin/echo "Current serial is ${SERIAL}"

    NEW_SERIAL=$(($SERIAL+1))
    /bin/echo "New serial is ${NEW_SERIAL}"
    /usr/bin/sed -i "s/${SERIAL}/${NEW_SERIAL}/g" $TMP_DIR/$ZONE_FILE

    # Clear any existing acme txt record(s)
    # Bear in mind this means you can only have 1 acme domain 
    # per zone
    /usr/bin/sed -i "s/${CHALLENGE_PREFIX}.*$//g" $TMP_DIR/$ZONE_FILE

    # Write the new acme txt record
    ACME_RECORD="${CHALLENGE}.\t10\tIN\tTXT\t\"${KEY}\""

    # TMPFS does something that disallows route from appending!
    # Make a new thing instead
    NEW_ZONE="${TMP_DIR}/${ZONE_FILE}.new"
    /bin/cat $TMP_DIR/$ZONE_FILE > $NEW_ZONE && \
    /bin/echo -e "${ACME_RECORD}" >> $NEW_ZONE
    /bin/echo "New zone revision generated at ${NEW_ZONE}"
    /usr/bin/named-checkzone $DOMAIN $NEW_ZONE && {
    /usr/bin/chown $BIND_USER:$BIND_USER $NEW_ZONE
    /bin/cp $NEW_ZONE $ZONE_DIR/$ZONE_FILE &&
    /usr/sbin/rndc reload &&
    /bin/rm $NEW_ZONE &&
    exit 0
    } || {
    echo "Error checking zone! Please inspect $NEW_ZONE for details"
    exit 1
    }
}

function dns_bind_local_rm(){
    # ACME things
    CHALLENGE_PREFIX="_acme-challenge"
    CHALLENGE=$1
    KEY=$2
    DOMAIN=$(/bin/echo ${CHALLENGE}|/bin/sed "s/${CHALLENGE_PREFIX}.//")

    # Copy the zone somewhere
    ZONE_FILE="$DOMAIN.zone"
    if [ -f $ZONE_DIR/$ZONE_FILE ]; then
            /bin/cp -p $ZONE_DIR/$ZONE_FILE $TMP_DIR
    else
            echo "${ZONE_FILE} not found in ${ZONE_DIR}"
            exit 1
    fi

    # Bump the serial number - should work for the vast majority of
    # zone layouts, but YMMV (especially if you use tildes)
    SERIAL=$(/bin/cat $TMP_DIR/$ZONE_FILE | \
    /usr/bin/tr '\n' '`' | \
    /usr/bin/egrep -o '^.*SOA.*\(.*\)' | \
    /usr/bin/egrep -o "${ZONE_SN_FORMAT}")
    /bin/echo "Current serial is ${SERIAL}"

    NEW_SERIAL=$(($SERIAL+1))
    /bin/echo "New serial is ${NEW_SERIAL}"
    /usr/bin/sed -i "s/${SERIAL}/${NEW_SERIAL}/g" $TMP_DIR/$ZONE_FILE

    # Clear any existing acme txt record(s)
    # Bear in mind this means you can only have 1 acme domain 
    # per zone
    /usr/bin/sed -i "s/${CHALLENGE_PREFIX}.*$//g" $TMP_DIR/$ZONE_FILE
    
    # TMPFS does something that disallows route from appending!
    # Make a new thing instead
    NEW_ZONE="${TMP_DIR}/${ZONE_FILE}.new"
    /bin/cat $TMP_DIR/$ZONE_FILE > $NEW_ZONE && \
    /bin/echo "New zone revision generated at ${NEW_ZONE}"
    /usr/bin/named-checkzone $DOMAIN $NEW_ZONE && {
    /usr/bin/chown $BIND_USER:$BIND_USER $NEW_ZONE
    /bin/cp $NEW_ZONE $ZONE_DIR/$ZONE_FILE &&
    /usr/sbin/rndc reload &&
    /bin/rm $NEW_ZONE &&
    exit 0
    } || {
    echo "Error checking zone! Please inspect $NEW_ZONE for details"
    exit 1
    }
}
