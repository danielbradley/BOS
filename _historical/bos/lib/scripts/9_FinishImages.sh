#!/bin/bash
#
#       Copyright (c) 2004-2006 Daniel Robert Bradley. All rights reserved.
#
#  Usage 9_FinishImages.sh <directory> <target>

main()
{
	find_base_dir $@
	read_headers $@
	process_arguments $@ &&
	run_finish_scripts
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
#	if [ $# -ne 2  ]
#	then
#		echo "Usage: 2_MountImages <Source dir> <Id>"
#		exit 1
#	fi
#
#	SOURCE=$1
#	TARGET=$2

	IMAGE_NAME=`basename $TARGET` &&
	MOUNT_POINT=$VAR_DIR/$NAMESPACE/$IMAGE_NAME &&
	TOOLS_MNT=$MOUNT_POINT/tools
	LOG=$TARGET/log/finish.log
}

run_finish_scripts()
{
        #echo ScriptDir:  $MOUNT_POINT/$PREP_SCRIPT_DIR/*.prep.script;

        for IMAGE_SPEC in $IMAGE_SPEC_DIR/*.spec
        do
                local IMAGE_MP=`$IMAGEINFO getImageMountPoint -f $IMAGE_SPEC`
                local PREPARE_SCRIPT=`$IMAGEINFO getImagePreparationScriptName -f $IMAGE_SPEC`
                if [ -n "$PREPARE_SCRIPT" ]
                then
                        #echo Running: $FILE
                        local FILE=`basename $PREPARE_SCRIPT`
#                 echo $CHROOT $MOUNT_POINT $TOOLS/env -i HOME=/ TERM=$TERM PATH=/usr/bin:/bin:$TOOLS $IMAGE_MP/$FILE finish
                        $CHROOT $MOUNT_POINT $TOOLS/env -i HOME=/ \
                                TERM=$TERM PATH=/usr/bin:/bin:$TOOLS $IMAGE_MP/$FILE finish >> $LOG 2>&1 &&
			printf "#"
                fi
        done
}

main $@
