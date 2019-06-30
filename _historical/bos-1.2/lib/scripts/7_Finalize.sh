#!/bin/bash
#
#       Copyright (c) 2004-2006 Daniel Robert Bradley. All rights reserved.
#

main()
{
	find_base_dir $@
	read_headers
        process_arguments $@

#	redirect_bin &&
#	finalize
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
        source $BASE_DIR/etc/bos.conf
}

process_arguments()
{
        if [ $# -ne 2 ]
        then
                echo "Usage: 3_PrepareChroot <Source dir> <Target file>"
                exit 1
        fi

        SOURCE=$1
        TARGET=$2

	IMAGE_NAME=`basename $TARGET`
        MOUNT_POINT=$VAR_DIR/$NAMESPACE/$IMAGE_NAME
}

redirect_bin()
{
	if [ ! -L $MOUNT_POINT/bin ]
	then
		rm -rf $MOUNT_POINT/bin &&
		ln -s boot/software/bin $MOUNT_POINT/bin
		chown 50:99 $MOUNT_POINT/bin
	fi
}

finalize()
{
	chown -R 50:99 $MOUNT_POINT/boot/configuration
	chown -R 50:99 $MOUNT_POINT/boot/scripts
	chown -R 50:99 $MOUNT_POINT/usr/scripts
}

main $@
