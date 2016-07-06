#!/usr/bin/env sh

BIN_PATH=/usr/local/bin
DM_PATH="$BIN_PATH/docker-machine"
DC_PATH="$BIN_PATH/docker-compose"
DM_VERSION="v0.7.0"
DC_VERSION="1.6.2"
HOST_FILE="/etc/hosts"
DM_VE="virtualbox"
DM_SHARED_PATH=$PWD
DM_NAME="dev"
DM_HOSTNAME="$(basename $DM_SHARED_PATH).$DM_NAME"
DC_FILE="$PWD/docker-compose.yml"

get_dm_tools () {
	mkdir -p $BIN_PATH
	if [ "X$(which docker-machine)" = "X" ]; then
		printf "%s" "Docker Machine is missing, it will be download and setting on $BIN_PATH..."
		sudo -- sh -c -e "curl -L https://github.com/docker/machine/releases/download/${DM_VERSION}/docker-machine-`uname -s`-`uname -m` 2>/dev/null > $DM_PATH";
		sudo chmod +x $DM_PATH
		printf "%s\n" "Done"
	fi

	if [ "X$(which docker-compose)" = "X" ]; then
		printf "%s" "Docker Compose is missing, it will be download and setting on $BIN_PATH..."
        sudo -- sh -c -e "curl -L https://github.com/docker/compose/releases/download/${DC_VERSION}/docker-compose-`uname -s`-`uname -m` 2>/dev/null > $DC_PATH";
        sudo chmod +x $DC_PATH
		printf "%s\n" "Done"
    fi
}

start_dm_ve () {
	if [ "X$($DM_PATH inspect $DM_NAME 2>&1)" = "XHost does not exist: \"$DM_NAME\"" ]; then
		printf "%s" "Docker Machine $DM_NAME did not exist. Creation of the docker machine..."
		$DM_PATH create -d $DM_VE $DM_NAME > /dev/null 2>&1
		printf "%s\n" "Done"
		shared_dm_ve
		set_hosts
	fi
		start_dc
}

shared_dm_ve () {
	TMP_SHARED_NAME="hosthome"
    TMP_SHARED_PATH=$HOME
	TMP_SHARED_MNT_PATH=$TMP_SHARED_PATH
	VBOX_MANAGE=$(which VBoxManage)
    if [ "X$OS" != "X" ]; then
        TMP_SHARED_NAME=""
        TMP_SHARED_PATH=""
		TMP_SHARED_MNT_PATH=""
		VBOX_MANAGE="C:\\Program Files\\Oracle\\VirtualBox\\VBoxManage"
		HOST_FILE=""
    fi                                                                          
    $DM_PATH stop $DM_NAME > /dev/null 2>&1
    $VBOX_MANAGE sharedfolder remove $DM_NAME --name $TMP_SHARED_NAME > /dev/null 2>&1
	if [ "X$DM_SHARED_PATH" != "X"  ]; then
		TMP_SHARED_NAME="$(basename $DM_SHARED_PATH)"
		TMP_SHARED_PATH=$DM_SHARED_PATH
		TMP_SHARED_MNT_PATH=$DM_SHARED_PATH
	fi
	printf "%s" "Creation of sharedfolder $DM_NAME with the current host folder..."
    $VBOX_MANAGE sharedfolder add $DM_NAME --name $TMP_SHARED_NAME --hostpath $TMP_SHARED_PATH --automount > /dev/null 2>&1
	$VBOX_MANAGE setextradata $DM_NAME VBoxInternal2/SharedFoldersEnableSymlinksCreate/$TMP_SHARED_NAME 1
	printf "%s\n%s" "Done" "Mount the sharedfolder..."
    $DM_PATH start $DM_NAME > /dev/null 2>&1
	$DM_PATH ssh $DM_NAME mkdir -p $TMP_SHARED_MNT_PATH > /dev/null 2>&1
	$DM_PATH ssh $DM_NAME sudo mount -t vboxsf -o defaults,uid=1000,gid=50 $TMP_SHARED_NAME $TMP_SHARED_MNT_PATH > /dev/null 2>&1
	printf "%s\n%s\n" "Done" "Docker Machine $DM_NAME is ready to use"
}

start_dc () {

	if [ "X$DC_FILE" != "X" ] && [ -f $DC_FILE  ]; then
		eval $($DM_PATH env $DM_NAME )
		printf "%s" "Execution of docker compose file $DC_FILE..."
		$DC_PATH -f $DC_FILE up --force-recreate -d > /dev/null 2>&1
		printf "%s\n" "Done"
	fi
}

set_hosts() {
    if [ ! -n "$(grep $DM_HOSTNAME $HOST_FILE)" ]; then
		sudo -- sh -c -e "echo '$($DM_PATH ip ${DM_NAME})\t$DM_HOSTNAME' >> $HOST_FILE";
	fi
	if [ -n "$(grep $DM_HOSTNAME $HOST_FILE)" ]; then
		printf "%s\n" "The IP address is $($DM_PATH ip ${DM_NAME}). It is  accessible with hostname $DM_HOSTNAME";
    fi
}

usage(){
	printf "%s\n" "help"
}

while getopts ":e:n:s:c:dh" opt; do
	case $opt in
	    e)
	    DM_VE="$OPTARG"
#	    shift # past argument=value
	    ;;
	    n)
		DM_NAME="$OPTARG"
#	    shift # past argument=value
		;;
		s)
		DM_SHARED_PATH="$OPTARG"
#		shift
		;;
		host)                                                       
	    DM_HOSTNAME="$OPTARG"                                                 
#	    shift                                                                       
	    ;;
		c)                                                       
	    DC_FILE="$OPTARG"                                                 
#	    shift                                                                       
	    ;;
		d)
		$DM_PATH rm -f $DM_NAME
		exit 0
#	    shift # past argument=value                                                 
	    ;;
		h)                                                                
		usage
#	    shift # past argument=value                                                 
	    ;;
		ls)                                                                  
	    $DM_PATH ls
		exit 0
#	    shift # past argument=value                                                 
	    ;;
		ssh)
	    $DM_PATH ssh $DM_NAME
		exit 0
#	    shift # past argument=value                                                 
	    ;;
		\?)
		echo "Invalid option: -$OPTARG" >&2
#		shift
		;;
		:)
		echo "Option -$OPTARG requires an argument." >&2
		exit 1
		;;
	    *)
	    DM_SHARED_PATH=$PWD                                                             
	    DM_NAME="dev"                                                                   
	    DM_HOSTNAME="$(basename $DM_SHARED_PATH).$DM_NAME"
	    DC_FILE="$PWD/docker-compose.yml"                                               
	            # unknown option
	    ;;
	esac
done


get_dm_tools
start_dm_ve
