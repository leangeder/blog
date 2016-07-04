#!/usr/bin/env sh

DM_PATH=$(which docker-machine)
DC_PATH=$(which docker-compose)
HOME_BIN_PATH=$HOME/bin
DM_VE="virtualbox"
DM_VERSION="v0.7.0"
DC_VERSION="1.6.2"
DM_SHARED_PATH=$PWD
DM_NAME="dev"
DM_HOSTNAME="$(basename $DM_SHARED_PATH).local"
DC_FILE="$PWD/docker-compose.yml"

get_dm_tools () {
	mkdir -p $HOME_BIN_PATH
	if [ "X$DM_PATH" = "X" ]; then
		printf "%s" "Docker Machine is missing, it will be download and setting on $HOME_BIN_PATH..."
		sudo curl -L https://github.com/docker/machine/releases/download/${DM_VERSION}/docker-machine-`uname -s`-`uname -m` 2>/dev/null > $HOME_BIN_PATH/docker-machine
		sudo chmod +x $HOME_BIN_PATH/docker-machine
		printf "%s\n" "Done"
	fi

	if [ "X$DC_PATH" = "X" ]; then
		printf "%s" "Docker Compose is missing, it will be download and setting on $HOME_BIN_PATH..."
        sudo curl -L https://github.com/docker/compose/releases/download/${DC_VERSION}/docker-compose-`uname -s`-`uname -m` 2>/dev/null > $HOME_BIN_PATH/docker-compose
        sudo chmod +x $HOME_BIN_PATH/docker-compose
		printf "%s\n" "Done"
    fi
	export PATH=$PATH:$(echo $HOME_BIN_PATH)
	DM_PATH=$(which docker-machine)
	DC_PATH=$(which docker-compose)
}

start_dm_ve () {
	if [ "X$(docker-machine inspect $DM_NAME 2>&1)" = "XHost does not exist: \"$DM_NAME\"" ]; then
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
		eval $($HOME_BIN_PATH/docker-machine env $DM_NAME )
		printf "%s" "Execution of docker compose file $DC_FILE..."
		$DC_PATH -f $DC_FILE up --force-recreate -d > /dev/null 2>&1
	fi
	printf "%s\n" "Done"
}

set_hosts() {
    if [ ! -n "$(grep $DM_HOSTNAME /etc/hosts)" ]; then
		sudo -- sh -c -e "echo '$(docker-machine ip ${DM_NAME})\t$DM_HOSTNAME' >> /etc/hosts";
	fi
	if [ -n "$(grep $DM_HOSTNAME /etc/hosts)" ]; then
		printf "%s\n" "The IP address is $(docker-machine ip ${DM_NAME}). It is  accessible with hostname $DM_HOSTNAME";
    fi
}

#for args in "$@"
#do
#case $i in
#    -e=*|--environnementenvironnement=*)
#    DM_VE="${i#*=}"
#    shift # past argument=value
#    ;;
#	-s=*|--shared_path=*)
#	DM_SHARED_PATH="${i#*=}"
#	shift
#	;;
#    *)
#	DM_VE="virtualbox"
#	DM_SHARED_PATH=
#            # unknown option
#    ;;
#esac
#done

get_dm_tools
start_dm_ve
