#!/bin/bash
#
#       Copyright (c) 2004-2006 Daniel Robert Bradley. All rights reserved.
#
#  Create image
#
#  Usage 1_CreateImage.sh <source packages dir> <target dir>
#
#	This script creates the mount point for the root partition
#	disk image.
#
#	It then interates through disk partition specification
#	scripts which create and mount partition images, then
#	populate them with directories and static files.
#

main()
{
	#printf "%s\n" "Stage 1: Create Images"

	find_base_dir $@
	read_headers $@
#s#	process_arguments $@
	create_target &&
	create_images
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
	LOG=$TARGET/log/create.log
}

process_arguments()
{
	if [ $# -ne 2 ]
	then
		"Usage: 1_CreateImage <Source dir> <Target dir>"
		exit 1
	fi

	SOURCE=$1
	TARGET=$2

#	IMAGE_NAME=`basename $TARGET` &&
#	MOUNT_POINT=$VAR_DIR/$NAMESPACE/$IMAGE_NAME
}

create_target()
{
	if [ ! -d ${TARGET} ]
	then
		printf "\tmkdir -p ${TARGET}\n" >> $LOG &&
		mkdir -p ${TARGET}
	fi
}

create_images()
{
	let r=0
	for IMAGE_SPEC in $IMAGE_SPEC_DIR/*.spec
	do
		create_image $IMAGE_SPEC >> $LOG 2>&1 &&
		if [ $? -eq 0 ]
		then
			printf " #"
		else
			printf " X"
			r=-1
		fi
	done
	return $r
}

create_image()
{
	local IMAGE_SPEC=$1
	local IMAGE_DIR=$TARGET
	local SCRIPT_DIR=$GLOBAL_PREP_SCRIPT_DIR

	if [ -f $IMAGE_SPEC ]
	then
		local IMAGE_SIZE=`imageinfo getImageSize -f $IMAGE_SPEC` &&
		local IMAGE_NAME=`imageinfo getImageName -f $IMAGE_SPEC` &&

		if [ "0" != "$IMAGE_SIZE" ]
		then
#			printf "\t\tlocating image: %s\n" $IMAGE_DIR/$IMAGE_NAME
#			printf "\t\t\tsize: %s\n" $IMAGE_SIZE

			if [ ! -f $IMAGE_DIR/$IMAGE_NAME ]
			then
				echo `which $DD`
				echo `which $MAKE_FS`

				local Dev=/dev
				if [ ! -f ${Dev}/zero ]
				then
					Dev=/system/devices
				fi

				printf "\tcreating image: %s\n" "$IMAGE_NAME ($IMAGE_SIZE MB)" &&

				local Output=`$DD if=${Dev}/zero of=$IMAGE_DIR/$IMAGE_NAME bs=1000000 count=$IMAGE_SIZE` &&
				let r=$?
				echo $Output
				local TEST=`echo $Output > grep "error"`
				if [ $r -ne 0 -o -n "$TEST" ]
				then
					return -1
				fi
				local Output=`$MAKE_FS -F $IMAGE_DIR/$IMAGE_NAME`
				r=$?
				echo $Output
				local TEST=`echo $Output > grep "error"`
				if [ $r -ne 0 -o -n "$TEST" ]
				then
					return -1
				fi
			fi
		fi
	fi
}

main $@
