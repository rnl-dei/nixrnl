#!/usr/bin/env bash

# Nuno Silva (RNL) - 2018
# To be invoked by mariadb when Node Status changes
# Logs calls to $LOG and sends emails
#
# based on http://galeracluster.com/documentation-webpages/notificationcmd.html

LOG=/dev/shm/wsrep_notify.log
SCRIPT=$(basename $0)
DISABLE_FILE=/dev/shm/$SCRIPT.disable

# don't send email by default
MAILTO=
SUBJECT="DB cluster status - $(hostname -s) ($(date +%T))"

SCRIPT_ARGS="$@"


my_date() {
	date '+%F %T'
}

do_mail() {

	# remove DISABLE_FILE if it's too old
	find $(dirname $DISABLE_FILE) -maxdepth 1 -mtime +1 -name $(basename $DISABLE_FILE) -type f -exec rm -vf {} +

	if test -e $DISABLE_FILE; then
		echo "not sending email because $DISABLE_FILE exists"
		return 0
	fi

if test -n "$MAILTO"; then
sendmail $MAILTO <<EOM
To: $MAILTO
Subject: $SUBJECT

$(cat)

--
`my_date`
$(hostname)

$0 $SCRIPT_ARGS
EOM

echo "sendmail ($?)" >&2

fi
}

# input: $MEMBERS
# output: $MEMBERS_SIZE and stdout
do_cluster_size() {
	local idx=0
	echo "=== Current member nodes ==="
	for NODE in $(echo $MEMBERS | sed s/,/\ /g); do
		echo "- $NODE"
		idx=$(( $idx + 1 ))
	done
	MEMBERS_SIZE=$idx
}

on_configuration_change() {
	do_cluster_size

cat <<EOM

=== Component Status ===
size:    $MEMBERS_SIZE
index:   $INDEX
status:  $STATUS
uuid:    $CLUSTER_UUID
primary: $PRIMARY

`my_date`
EOM
}

on_status_update() {
cat <<EOM
status:  $STATUS
`my_date`
EOM
}

echo "$(my_date) $0 $SCRIPT_ARGS" >> $LOG

COM=on_status_update # not a configuration change by default

while test $# -gt 0 ; do
	case $1 in
		--enable)
			echo "removing $DISABLE_FILE ..."
			rm -f $DISABLE_FILE
			exit $?
			;;
		--disable)
			echo "creating $DISABLE_FILE ..."
			touch $DISABLE_FILE
			exit $?
			;;
		--mailto)
			MAILTO=$2
			shift
			;;
		--status)
			STATUS=$2
			SUBJECT="${SUBJECT} ${STATUS}"
			shift
			;;
		--uuid)
			CLUSTER_UUID=$2
			shift
			;;
		--primary)
			PRIMARY="$2"
			COM=on_configuration_change
			shift
			;;
		--index)
			INDEX=$2
			shift
			;;
		--members)
			MEMBERS=$2
			do_cluster_size > /dev/null # calculate MEMBERS_SIZE
			SUBJECT="${SUBJECT} ${MEMBERS_SIZE} nodes"
			shift
			;;
	esac
	shift
done

# Undefined means node is shutting down (probably because we wanted it to)
if test "$STATUS" = "Undefined" ; then
	echo "$STATUS nomail" >> $LOG.info
else
	$COM 2>&1 | tee -a $LOG.info | do_mail
	exit 0
fi
