#!/bin/bash
#
#       Copyright (c) 2004-2006 Daniel Robert Bradley. All rights reserved.
#

main()
{
	find_base_dir $@
	read_headers $@
        process_arguments
	
	build_X
	return
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
}

process_arguments()
{
	IMAGE_NAME=`basename $TARGET`
        MOUNT_POINT=$VAR_DIR/$NAMESPACE/$IMAGE_NAME
}

build_X()
{
	local X11=`cat $MOUNT_POINT/mnt/software/x11.txt`
	
	for DIRECTORY in $X11
	do
		build_packages $DIRECTORY root &&
		activate_packages $DIRECTORY libraries /usr/X11R6/software &&
		run_ldconfig
	done
}

build_packages()
{
	echo "Building $DIRECTORY"

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
			SCRIPTS="$SCRIPTS $SCRIPT"
		done
	fi

	for SCRIPT in $SCRIPTS
	do
		echo Running $SCRIPT
		local PKG=`basename $SCRIPT .sh`
		$CHROOT $MOUNT_POINT /tools/bin/env -i HOME=/ TERM=$TERM PATH=$SOFTWARE_BASE/bin:/usr/X11R6/software/bin:/tools/bin \
			$SU $USER -c "/mnt/software/$DIRECTORY/$SCRIPT > /mnt/log/$PKG.log 2>&1" &&
		if [ $? != 0 ]
		then
			return -1
		fi
	done
}

activate_packages()
{
	local DIRECTORY=$1
	local PKG_TYPE=$2
	local SW_BASE=$3

	local ARGS=""
	local PACKAGES=""

	if [ "$PKG_TYPE" == "libraries" ]
	then
		ARGS="-li"
	fi

	if [ "$PKG_TYPE" == "runtimes" ]
	then
		ARGS="-li"
	fi

	if [ -z "$SW_BASE" ]
	then
		SW_BASE=$SOFTWARE_BASE
	fi

	if [ -f $MOUNT_POINT/mnt/software/$DIRECTORY/activate.txt ]
	then

		PACKAGES=`cat $MOUNT_POINT/mnt/software/$DIRECTORY/activate.txt`

		for PACKAGE in $PACKAGES
		do
			local CATEGORY=`dirname $PACKAGE` &&
			local PKG=`basename $PACKAGE .sh`

			echo Activating $PACKAGE $CATEGORY-$PKG

			local LINKS=""
			LINKS=`ls -l $MOUNT_POINT$SW_BASE/bin | grep "/$PKG"`
			LINKS="$LINKS`ls -l $MOUNT_POINT$SW_BASE/sbin | grep $PKG`"
			LINKS="$LINKS`ls -l $MOUNT_POINT$SW_BASE/lib | grep $PKG`"

			if [ -z "$LINKS" ]
			then
				echo Activating $CATEGORY/$PKG &&

				$CHROOT $MOUNT_POINT /tools/bin/env -i \
				        HOME=/ \
					TERM=$TERM \
					PS1='\u@\w\$ ' \
					PATH=/tools/bin \
					$SU system -c "activate $ARGS $SW_BASE/$PKG_TYPE/$CATEGORY/$PKG* > /mnt/log/$PKG.act.log 2>&1" 
				if [ $? != 0 ]
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
