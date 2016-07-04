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
		sudo curl -L https://github.com/docker/machine/releases/download/${DM_VERSION}/docker-machine-`uname -s`-`uname -m` > $HOME_BIN_PATH/docker-machine
		sudo chmod +x $HOME_BIN_PATH/docker-machine
	fi

	if [ "X$DC_PATH" = "X" ]; then                                              
        sudo curl -L https://github.com/docker/compose/releases/download/${DC_VERSION}/docker-compose-`uname -s`-`uname -m` > $HOME_BIN_PATH/docker-compose
        sudo chmod +x $HOME_BIN_PATH/docker-compose
    fi
	export PATH=$PATH:$(echo $HOME_BIN_PATH)

}

start_dm_ve () {
	if [ "X$(docker-machine inspect $DM_NAME 2>&1)" = "XHost does not exist: \"$DM_NAME\"" ]; then
		docker-machine create -d $DM_VE $DM_NAME > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			printf "%s\n" "Docker Machine $DM_NAME has been create"
		fi
	fi
}

shared_dm_ve () {
	TMP_SHARED_NAME=""
    TMP_SHARED_PATH=""
	TMP_SHARED_MNT_PATH="/home/$USER"
    if [ "X$OS" != "X" ]; then
        TMP_SHARED_NAME=""
        TMP_SHARED_PATH=""
		TMP_SHARED_MNT_PATH=""
    else
        TMP_SHARED_NAME="hosthome"
        TMP_SHARED_PATH=$HOME
		TMP_SHARED_MNT_PATH=$HOME
    fi                                                                          
    docker-machine stop $DM_NAME > /dev/null 2>&1
    VBoxManage sharedfolder remove $DM_NAME --name $TMP_SHARED_NAME > /dev/null 2>&1
	if [ "X$DM_SHARED_PATH" != "X"  ]; then
		TMP_SHARED_NAME="$(basename $DM_SHARED_PATH)"
		TMP_SHARED_PATH=$DM_SHARED_PATH
		TMP_SHARED_MNT_PATH=$DM_SHARED_PATH
	fi
    VBoxManage sharedfolder add $DM_NAME --name $TMP_SHARED_NAME --hostpath $TMP_SHARED_PATH --automount > /dev/null 2>&1
	VBoxManage setextradata $DM_NAME VBoxInternal2/SharedFoldersEnableSymlinksCreate/$TMP_SHARED_NAME 1
    docker-machine start $DM_NAME > /dev/null 2>&1
	docker-machine ssh $DM_NAME mkdir -p $TMP_SHARED_MNT_PATH > /dev/null 2>&1
	docker-machine ssh $DM_NAME sudo mount -t vboxsf -o defaults,uid=1000,gid=50 $TMP_SHARED_NAME $TMP_SHARED_MNT_PATH > /dev/null 2>&1
	printf "%s\n" "Docker Machine $DM_NAME is ready to use"
}

start_dc () {

	if [ "X$DC_FILE" != "X" ] && [ -f $DC_FILE  ]; then
		eval $($HOME_BIN_PATH/docker-machine env $DM_NAME )
		docker-compose -f $DC_FILE up --force-recreate -d
	fi
}

set_hosts() {
    if [ ! -n "$(grep $DM_HOSTNAME /etc/hosts)" ]; then
		sudo -- sh -c -e "echo '$(docker-machine ip ${DM_NAME})\t$DM_HOSTNAME' >> /etc/hosts";
	fi
	if [ -n "$(grep $DM_HOSTNAME /etc/hosts)" ]; then
		printf "%s\n" "The IP address is $(docker-machine ip ${DM_NAME}) and also accessible with hostname $DM_HOSTNAME";
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
shared_dm_ve
start_dc
set_hosts
