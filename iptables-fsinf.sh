#!/bin/sh
### BEGIN INIT INFO
# Provides:          iptables
# Required-Start:    $local_fs
# Required-Stop:     $local_fs
# X-Start-Before:    $network
# X-Stop-Before:     $network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start daemon at boot time
# Description:       Enable service provided by daemon.
### END INIT INFO

exec_dir=`dirname $(readlink -f $0)`
cd $exec_dir

[ -z $DRYRUN ]       && DRYRUN='n'

# base directories:
[ -z $CONFBASEDIR ]  && CONFBASEDIR='/etc/fw-rules'
[ -z $SHAREDIR ]     && SHAREDIR='/usr/share/fw-rules'

# important directories:
[ -z $INCLUDEDIR ]   && INCLUDEDIR="$SHAREDIR/include/"
[ -z $CONFDIR ]      && CONFDIR="$CONFBASEDIR/conf.d"
[ -z $INITDIR ]      && INITDIR="$CONFBASEDIR/init.d"

# default settings:
[ -z $ENABLE_V6 ] && ENABLE_V6='y'
[ -z $ENABLE_V4 ] && ENABLE_v4='y'

# include functions
for file in $(find $INCLUDEDIR -type f -or -type l | sort | grep '.sh$')
do
	. $file
done

for file in $(find $CONFDIR -regex $CONFDIR'/[0-9][0-9].*' -and '(' -type f -or -type l ')' | sort)
do
	. $file
done


start() {
	if [ "$ENABLED" != 'y' ]; then
		echo '$ENABLED is not set, so not configuring the firewall.'
		echo "Please set ENABLED='y' in a config-file in $CONFDIR."
		return
	fi
	# initialize:
	init

	# add global ports:
	global_ports

	# execute additional rules the system has in $INITDIR
	echo
	echo "# Add rules found in $INITDIR"
	#for file in $(find $INITDIR -type f -or -type l | sort | grep '/[0-9][0-9]')
	for file in $(find $INITDIR -regex $INITDIR'/[0-9][0-9].*' -and '(' -type f -or -type l ')' | sort)
	do
		echo $file
		. $file
	done
	echo "# Finished adding rules found in $INITDIR"
	echo 

	# COUNT, ICMP and BLOCKED chains are inserted last, but on top of our
	# filter-rules.

	# allow only some icmp
	icmp

	# block some hosts:
	block_hosts

	# count traffic:
	count_traffic
}

case "$1" in
start)
	start
	;;
stop)
	reset
	;;
force-reload|restart)
	reset
	start
	;;
*)
	echo "Usage: /etc/init.d/networking {start|stop|restart|force-reload}"
	exit 1
	;;
esac

exit 0
