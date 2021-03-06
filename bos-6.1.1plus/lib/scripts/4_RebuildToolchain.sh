#!/bin/bash
#
#       Copyright (c) 2004-2006 Daniel Robert Bradley. All rights reserved.
#

main()
{
	find_base_dir $@
	read_headers $@
        process_arguments &&

	LOG="$TARGET/log/toolchain.log"

	rebuild_toolchain &&
	activate_toolchain
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
#        if [ $# -ne 2  ]
#       then
#                echo "Usage: 4_RebuildToolchain.sh <Source dir> <Target file>"
#                exit 1
#        fi
#
#        SOURCE=$1
#        TARGET=$2

	IMAGE_NAME=`basename $TARGET`
        MOUNT_POINT=$VAR_DIR/$NAMESPACE/$IMAGE_NAME
}

rebuild_toolchain()
{

#	mkdir -p $MOUNT_POINT/$TC_BUILD_DIR &&
#	chmod 1777 $MOUNT_POINT/$TC_BUILD_DIR &&

	#echo "35.189.51.245 cdn.securizant.org" > $MOUNT_POINT/system/default/settings/system/meta/hosts

	chmod 644 $MOUNT_POINT/local/settings/system/meta/*
	ln -sf ../system/meta/hosts $MOUNT_POINT/local/settings/lsb

	for TOOL in linux-libc-headers glibc binutils gcc
	do
	echo $CHROOT $MOUNT_POINT /tools/bin/env -i RESOURCE_URL=$RESOURCE_URL HOME=/ TERM=$TERM \
			PATH=/system/software/bin:/bin:/tools/bin \
			$SU system -s /tools/bin/bash -c "/mnt/software/toolchain/$TOOL.sh +h" >> $LOG 2>&1 
	$CHROOT $MOUNT_POINT /tools/bin/env -i RESOURCE_URL=$RESOURCE_URL HOME=/ TERM=$TERM LC_ALL=POSIX \
			PATH=/system/software/bin:/bin:/tools/bin \
			$SU system -s /tools/bin/bash -c /mnt/software/toolchain/$TOOL.sh +h >> $LOG 2>&1
	if [ $? -eq 0 ]
	then
		printf " #"
	else
		printf " X"
		return -1;
	fi

	done
}

activate_toolchain()
{
	echo "Activating toolchain" >> $LOG
	if [ ! -L $MOUNT_POINT$SOFTWARE_BASE/lib/libgcc_s.so ]
	then
		$CHROOT $MOUNT_POINT /tools/bin/env -i \
		        HOME=/ \
			TERM=$TERM \
			PS1='\u@\w\$ ' \
			PATH=/tools/bin \
			$SU system -c activate\ -li\ $SOFTWARE_BASE/commands/development/gnu-4.0.3 >> $LOG 2>&1
	fi
}

main $@

