#!/bin/bash
#
#       Copyright (c) 2004-2006 Daniel Robert Bradley. All rights reserved.
#

main()
{
	find_base_dir $@ &&
	read_headers $@ &&
        process_arguments &&
	build_system
}

find_base_dir()
{
        local THIS_DIR=$PWD
        local EXE_DIR=`dirname $0`
        cd $EXE_DIR/../..
        BASE_DIR=`pwd`
        cd $THIS_DIR
}

read_headers()
{
	PROJECT_DIR=`dirname $1`
	source $1
        source $BASE_DIR/etc/bos.conf

        if [ -n "$2" ]
        then
        	PROFILE="$2"
        fi
}

process_arguments()
{
	IMAGE_NAME=`basename $TARGET`
        MOUNT_POINT=$VAR_DIR/$NAMESPACE/$IMAGE_NAME
	LOG=$TARGET/log/system.log
}

build_system()
{
	local PROFILE=$MOUNT_POINT/mnt/software/${PROFILE}

	#	The profile file specifies the order directories
	#	should be built in.
	#
	#	Each line has: ACCOUNT DIRECTORY TARGET
	#
	#	The type indicates to "activate" how to activate
	#	the package into the system namespace. The owner
	#	indicates the account that should build the package
	#	(usually system or root). The target indicates
	#	where below the root of the system partition the
	#	package should be installed eg. software/libraries
	#	vs X11R6/software/libraries.
	#
	#	Each has:
	#	o  account
	#	o  software base (eg libraries, commands)
	#	o  need for ld_config

	while read LINE
	do
		DIRPROFILE=`echo $LINE | cut -d'#' -f1`
		if [ -n "$DIRPROFILE" ]
		then
			#echo $DIRPROFILE
			local ACCOUNT=`echo $DIRPROFILE | cut -d' ' -f1`
			local DIRECTORY=`echo $DIRPROFILE | cut -d' ' -f2`
			local TYPE=`echo $DIRPROFILE | cut -d' ' -f3`
			local TARGET=`echo $DIRPROFILE | cut -d' ' -f4`

			echo "5_BuildSystem.sh: $ACCOUNT : $DIRECTORY : $TYPE : $TARGET" >> $LOG 2>&1
			printf "$ACCOUNT:$DIRECTORY ["

			build_packages $DIRECTORY $ACCOUNT 

			if [ $? -eq 0 ]
			then
				echo "] Finished"
			else
				echo "] Error"
				return -1
			fi

			if [ -n "$TYPE" ]
			then
				echo "5_BuildSystem.sh: activating: $DIRECTORY" >> $LOG 2>&1
				activate_packages $DIRECTORY $TYPE $TARGET
			fi
			run_ldconfig >> $LOG 2>&1
		fi

	done < $PROFILE

}

build_packages()
{
	echo "5_BuildSystem: building $DIRECTORY" >> $LOG 2>&1

	local DIRECTORY=$1
	local USER=$2
	local SCRIPTS=""

	if [ -z "$2" ]
	then
		USER=system
	fi

	if [ -f $MOUNT_POINT/mnt/software/$DIRECTORY/order.txt ]
	then
		SCRIPTS=`cat $MOUNT_POINT/mnt/software/$DIRECTORY/order.txt`
	else
		for FQ_SCRIPT in $MOUNT_POINT/mnt/software/$DIRECTORY/*.sh
		do
			local SCRIPT=`basename $FQ_SCRIPT`
			if [ "*.sh" != "$SCRIPT" ]
			then
				SCRIPTS="$SCRIPTS $SCRIPT"
			fi
		done
	fi

	for SCRIPT in $SCRIPTS
	do
		local SCR=`basename $SCRIPT`
		run_build_script $SCRIPT
		if [ $? -eq 0 ]
		then

			printf "#"
		else
			printf "(%s)X" $SCR
			echo "5_BuildSystem: error building: $SCRIPT" >> $LOG
			exit -1
		fi
	done
	if [ ! $? -eq 0 ]
	then
		echo "Exit in loop"
	fi
}

run_build_script()
{
	local SCRIPT=$1
	local PKG=`basename $SCRIPT .sh`
	#	Removed /usr/X11R6/software/bin from PATH
	$CHROOT $MOUNT_POINT /tools/bin/env -i RESOURCE_URL=$RESOURCE_URL HOME=/ TERM=$TERM PATH=/system/software/bin:/tools/bin \
		$SU $USER -s /tools/bin/bash -c "/mnt/software/$DIRECTORY/$SCRIPT > /mnt/log/${PKG}.log 2>&1"
}

activate_packages()
{
	local DIRECTORY=$1	# Directory to retrieve activate list from
	local PKG_TYPE=$2	# Type of package (how to activate)
	local SW_BASE_PREFIX=$3	# Target to activate

	local ARGS=""
	local PACKAGES=""

	if [ "$PKG_TYPE" == "libraries" -o "$PKG_TYPE" == "runtimes"  ]
	then
		ARGS="-li"
	fi

	#	/usr/software
	#	/usr/X11R6/software
	
	#	If _no_ system prefix is defined
	if [ -z "$SW_BASE_PREFIX" ]
	then
		SW_BASE=$SYSTEM_BASE/software
	else
		SW_BASE=$SYSTEM_BASE/$SW_BASE_PREFIX/software
	fi

	if [ -f $MOUNT_POINT/mnt/software/$DIRECTORY/activate.txt ]
	then

		PACKAGES=`cat $MOUNT_POINT/mnt/software/$DIRECTORY/activate.txt`

		for PACKAGE in $PACKAGES
		do
			local CATEGORY=`dirname $PACKAGE` &&
			local PKG=`basename $PACKAGE .sh`

			#echo Activating $PACKAGE $CATEGORY-$PKG

			local LINKS=""
			LINKS=`ls -l $MOUNT_POINT$SW_BASE/bin | grep "$PACKAGE"`
			LINKS="$LINKS`ls -l $MOUNT_POINT$SW_BASE/sbin | grep $PACKAGE`"
			LINKS="$LINKS`ls -l $MOUNT_POINT$SW_BASE/lib | grep $PACKAGE`"

			if [ -z "$LINKS" ]
			then
				#echo Activating $CATEGORY/$PKG &&

				$CHROOT $MOUNT_POINT /tools/bin/env -i \
				        HOME=/ \
					TERM=$TERM \
					PS1='\u@\w\$ ' \
					PATH=/tools/bin \
					$SU system -s /tools/bin/bash -c "echo activate $ARGS $SW_BASE/$PKG_TYPE/$CATEGORY/$PKG* > /mnt/log/$PKG.act.log 2>&1" 
				$CHROOT $MOUNT_POINT /tools/bin/env -i \
				        HOME=/ \
					TERM=$TERM \
					PS1='\u@\w\$ ' \
					PATH=/tools/bin \
					$SU system -s /tools/bin/bash -c "activate $ARGS $SW_BASE/$PKG_TYPE/$CATEGORY/$PKG* >> /mnt/log/$PKG.act.log 2>&1" 
				if [ $? -ne 0 ]
				then
					return -1
				fi
			fi
		done
	fi
}

run_ldconfig()
{
	echo "Registering libraries with system - ldconfig"
	$CHROOT $MOUNT_POINT /tools/bin/env -i \
		HOME=/ TERM=$TERM PATH=$SOFTWARE_BASE/bin:/tools/bin \
			$SOFTWARE_BASE/sbin/ldconfig
}

main $@
