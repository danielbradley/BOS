#!/bin/bash
#
#       Copyright (c) 2004-2006 Daniel Robert Bradley. All rights reserved.
#

SU=/tools/bin/su

main()
{
	find_base_dir $@
	read_headers $@
        process_arguments

        #prepare_for_build &&
	#create_sbin &&
	build_kernels
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
	LOG=$TARGET/log/kernels.log
	IMAGE_NAME=`basename $TARGET`
        MOUNT_POINT=$VAR_DIR/$NAMESPACE/$IMAGE_NAME
}

prepare_for_build()
{
	#  Replace scripts for local software

	rm -f $MOUNT_POINT/$KERNEL_SCRIPT_DIR/*.sh &&
	mkdir -p $MOUNT_POINT/$KERNEL_SCRIPT_DIR &&
	cp -f $SRC_KERNEL_GEN_DIR/*.sh $MOUNT_POINT/$KERNEL_SCRIPT_DIR/ &&
        chmod 555 $MOUNT_POINT/$KERNEL_SCRIPT_DIR &&
        chmod 555 $MOUNT_POINT/$KERNEL_SCRIPT_DIR/*.sh &&

	mkdir -p $MOUNT_POINT/$KERNEL_BUILD_DIR &&
	chmod 1777 $MOUNT_POINT/$KERNEL_BUILD_DIR
}

create_sbin()
{
	if [ ! -L $MOUNT_POINT/sbin ]
	then
		ln -s boot/software/sbin $MOUNT_POINT/sbin
	fi
}

build_kernels()
{
	for KERNEL_SCRIPT in $MOUNT_POINT/mnt/software/kernels/*.sh
	do
		build_kernel $KERNEL_SCRIPT
		if [ $? -eq 0 ]
		then
			printf " #"
		else
			printf " X"
			echo "bos_build_kernels: error building $KERNEL_SCRIPT"
			return -1
		fi
	done
}

build_kernel()
{
	local KERNEL_SCRIPT=$1
	
	local SCRIPT=`basename $KERNEL_SCRIPT`
	local PKG=`basename $SCRIPT .sh`

	$CHROOT $MOUNT_POINT /tools/bin/env -i RESOURCE_URL=$RESOURCE_URL HOME=/ TERM=$TERM \
		PATH=/system/software/commands/development/gnu-2.95.3/bin:/system/software/bin:/bin:/tools/bin \
		$SU system -s /tools/bin/bash -c "/mnt/software/kernels/$SCRIPT >> /mnt/log/${PKG}.log 2>&1" 
}

#
#  Copies the source files from the host to the chrooted environment if
#  the files differ.
#
copy_sources()
{
	local PREFIX=$1
	local ID=$2

	local SRC_DEST=$MOUNT_POINT/mnt/source

	echo SOURCE: $SOURCE
	echo ID:     $ID
	echo PREFIX: $PREFIX
	echo
	echo copying from $SOURCE/$ID/${PREFIX}*

	if [ TRUE ]
	then

		for FQ_HOST_FILE in $SOURCE/$ID/${PREFIX}*
		do
			local FILENAME=`basename $FQ_HOST_FILE`

			local RESULT=`diff -N --brief $FQ_HOST_FILE $SRC_DEST/$ID/$FILENAME`

			if [ "$RESULT" != "" ]
			then
				echo $FQ_HOST_FILE
				cp $FQ_HOST_FILE $SRC_DEST/$ID/$FILENAME
				chmod 755 $SRC_DEST/$ID/$FILENAME
				echo chmod 755 $SRC_DEST/$ID/$FILENAME
			fi
		done

	else
		echo The other one
		echo cp ${FQ_PREFIX}* $SRC_DEST
	fi
}

main $@
