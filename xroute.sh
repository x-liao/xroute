#/usr/bin/env bash

# 用于备份和恢复隧道路由表
# xliao
# 2019-05-22


inte_list=($(ls /sys/class/net))
inte_excluded='ppp ens eth lo'
backup_path='/etc/xroute'

if [[ ! -d $backup_path ]]; then
	mkdir $backup_path
fi

backup(){
	local inte=$1

	for i in $(ls /sys/class/net); do
		[ i == $inte ] && is_device=1; break
	done

	if [[ ! is_device ]]; then
		echo "Cannot find device $inte"
		return 1
	fi

	ip route show dev $inte | grep -v 'kernel' > "${backup_path}/${inte}"
}

routeUp(){
	route_file=$1
	awk '{print "ip route add "$0}' $route_file | bash
}


backupAll(){
	for inte_name in ${inte_list[@]}; do
		if [[ ! $inte_excluded =~  ${inte_name:0:3} ]]; then
			echo "Backup $inte_name"
			backup $inte_name
		fi
	done
}

routeUpAll(){
	backup_list=$(ls $backup_path)
	for backup_name in ${backup_list}; do
		if echo "${inte_list[@]}" | grep -w $backup_name &>/dev/null; then
			echo "Route Up $backup_name" 
			routeUp $backup_path/$backup_name
		else
			echo "Cannot find device $backup_name" 
		fi
	done
}

printHelp(){
cat << "EOF"

用于备份和恢复隧道路由表
xliao

General Options:
  -h                          Show help.
  -b                          Backup [DEVICE] | [all]
  -r                          Restore [DEVICE] | [all]
  -l                          Show Backup

EOF

}

showBackup(){
	for backup in $(ls $backup_path); do
		line=$(cat $backup_path/$backup | wc -l)
		echo "$backup					$line"
	done
}

if [[ ! -n $1 ]]; then
	printHelp
	exit 0
fi

while getopts b:r:lh option; do
	case $option in
	b)
		if [[ $OPTARG == 'all' ]]; then
			echo "backup all"
			backupAll
		else
			echo "backup $OPTARG"
			backup $OPTARG
		fi
		;;
	r)
		if [[ $OPTARG == 'all' ]]; then
			echo "Restore all"
			routeUpAll
		else
			echo "routeUp $OPTARG"
			routeUp $backup_path/$OPTARG
		fi
		;;
	l)
		showBackup
		;;
	h)
		printHelp
		;;
	*)
		printHelp
		;;
	esac
done


