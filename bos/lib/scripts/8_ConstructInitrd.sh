#!/bin/bash
#
#       Copyright (c) 2004-2006 Daniel Robert Bradley. All rights reserved.
#

main()
{
	find_base_dir $@ &&
	read_headers $@ &&
        process_arguments &&
	build_boot
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
	LOG=$TARGET/log/initrd.log
}

process_arguments()
{
	IMAGE_NAME=`basename $TARGET`
        MOUNT_POINT=$VAR_DIR/$NAMESPACE/$IMAGE_NAME
}

build_boot()
{
	echo "" > ${LOG}
        for FQ_SCRIPT in $MOUNT_POINT/mnt/software/initrd/*.sh
        do
		run_build_script $FQ_SCRIPT >> ${LOG} 2>&1
		if [ $? -eq 0 ]
		then
			printf " #"
		else
			printf " X"
#			echo "bos_build_initrd: error building $FQ_SCRIPT" >> $LOG
			return -1
		fi
	done

        #  If the above is performed in parallel then wait for processes to finish
        wait
}

run_build_script()
{
	local FQ_SCRIPT=$1
	local SCRIPT=`basename $FQ_SCRIPT`
	local PKG=`basename $SCRIPT .sh`

       	echo "<script>"
       	echo "<command>${FQ_SCRIPT}</command>"
        echo "<result>"

#	$CHROOT $MOUNT_POINT /tools/bin/env -i RESOURCE_URL=$RESOURCE_URL HOME=/ TERM=$TERM PATH=$SOFTWARE_BASE/bin:/tools/bin \
#		$SU -s /tools/bin/bash \
#		-c "/mnt/software/initrd/$SCRIPT > /mnt/log/initrd-${PKG}.log.sh 2>&1"
	$CHROOT $MOUNT_POINT /tools/bin/env -i RESOURCE_URL=$RESOURCE_URL HOME=/ TERM=$TERM PATH=$SOFTWARE_BASE/bin:/tools/bin \
		$SU -s /tools/bin/bash -c "/mnt/software/initrd/$SCRIPT"
	if [ $? -eq 0 ]
	then
		echo "</result>"
		echo "</script>"
		return 0
	else
		echo "</result>"
		echo "</script>"
		return -1
	fi
}

main $@
