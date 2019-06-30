#!/bin/bash
#
#       Copyright (c) 2004-2006 Daniel Robert Bradley. All rights reserved.
#
#
#  Prepare Images
#
#  Usage 3_MountImages.sh <directory> <target>

main()
{
	find_base_dir $@
	read_headers $@
	process_arguments $@ 
	prepare_images &&
	run_prepare_scripts
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
	LOG=$TARGET/log/prepare.log
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
}

prepare_images()
{
	for IMAGE_SPEC in $IMAGE_SPEC_DIR/*.spec
	do
		prepare_image $IMAGE_SPEC >> $LOG 2>&1
		if [ $? -eq 0 ]
		then
			printf " #"
		else
			printf " X"
		fi
	done
}

prepare_image()
{
#	@param $1 image_spec 

	local IMAGE_SPEC=$1

	local FLAGS=`$IMAGEINFO getImageMountFlags -f $IMAGE_SPEC`
	local FS_TYPE=`$IMAGEINFO getImageFilesystem -f $IMAGE_SPEC`

	local IMAGE_MP=`$IMAGEINFO getImageMountPoint -f $IMAGE_SPEC`
	local IMAGE_NAME=`$IMAGEINFO getImageName -f $IMAGE_SPEC`
	local IMAGE_MP_DIRNAME=`dirname $IMAGE_MP`

	local Check=$MOUNT_POINT$IMAGE_MP
	if [ "${FS_TYPE}" == "ext2" ]
	then
		Check="$MOUNT_POINT$IMAGE_MP/lost+found"
	fi
	
	if [ -d "${Check}" ]
	then
		local PREPARE_SCRIPT=`$IMAGEINFO getImagePreparationScriptName -f $IMAGE_SPEC`

		create_directories_and_copy_resources $IMAGE_SPEC
		create_links $IMAGE_SPEC

		if [ -n "$PREPARE_SCRIPT" ]
		then
			printf "\tcp $RESOURCE_DIR/$PREPARE_SCRIPT $MOUNT_POINT$IMAGE_MP\n"
			cp $RESOURCE_DIR/$PREPARE_SCRIPT $MOUNT_POINT$IMAGE_MP
			chmod a+x $MOUNT_POINT$IMAGE_MP/*.script
		fi
	fi
}

create_directories_and_copy_resources()
{
	local IMAGE_SPEC=$1
	local IMAGE_MP=`$IMAGEINFO getImageMountPoint -f $IMAGE_SPEC`
	local BASE=$MOUNT_POINT$IMAGE_MP
	local SUBDIRECTORIES=`$IMAGEINFO getSubdirectories -f $IMAGE_SPEC`

	local ImageSpecFile=`basename $IMAGE_SPEC`

	printf "\t\tCreating directores for: %s\n" $ImageSpecFile
#	printf "\t\t\tBase directory: %s\n" $BASE

	for DIRECTORY in $SUBDIRECTORIES
	do
		local DIR_SOURCE=`$IMAGEINFO getDirSource $DIRECTORY -f $IMAGE_SPEC`

		#
		#	We test whether the created directory is a
		#	directory because it may very well be removed
		#	later and replaced with a link into the system
		#	image. If it has we do not want to change it.
		#

		mkdir -p $MOUNT_POINT/$IMAGE_MP/$DIRECTORY &&
		if [ -d $MOUNT_POINT/$IMAGE_MP/$DIRECTORY -a -n "$DIR_SOURCE" ]
		then
			#echo "$DIR_SOURCE"
			#printf "\tcp -R $RESOURCE_DIR/$DIR_SOURCE/* $MOUNT_POINT/$IMAGE_MP/$DIRECTORY\n"

			if [ -d $RESOURCE_DIR/$DIR_SOURCE ]
			then
				cp -R $RESOURCE_DIR/$DIR_SOURCE/* $MOUNT_POINT/$IMAGE_MP/$DIRECTORY
				if [ $? -ne 0 ]
				then
					echo "Could not copy: $DIR_SOURCE"
				fi
			else
				echo "Does not exist: $RESOURCE_DIR/$DIR_SOURCE"
 			fi
		fi
	done
}

create_links()
{
	local IMAGE_SPEC=$1
	local IMAGE_MP=`$IMAGEINFO getImageMountPoint -f $IMAGE_SPEC`
	local BASE=$MOUNT_POINT$IMAGE_MP
	local LINKS=`$IMAGEINFO getLinks -f $IMAGE_SPEC`

#	printf "\t\tCreating links for: %s\n" $IMAGE_SPEC
#	printf "\t\t\tBase directory: %s\n" $BASE

	for LINK in $LINKS
	do
		local TARGET=`$IMAGEINFO getLinkTarget $LINK -f $IMAGE_SPEC`

		if [ -n "$TARGET" ]
		then
			if [ ! -h $MOUNT_POINT/$IMAGE_MP/$LINK ]
			then
#				echo ln -sf $TARGET $MOUNT_POINT/$IMAGE_MP/$LINK
				ln -sf $TARGET $MOUNT_POINT/$IMAGE_MP/$LINK
				if [ $? != 0 ]
				then
					printf "ln -sf $TARGET $MOUNT_POINT/$IMAGE_MP/$LINK (failed)\n"
				fi
			fi
		fi
	done
}

run_prepare_scripts()
{
        #echo ScriptDir:  $MOUNT_POINT/$PREP_SCRIPT_DIR/*.prep.script;

        for IMAGE_SPEC in $IMAGE_SPEC_DIR/*.spec
        do
        	run_prepare_script $IMAGE_SPEC >> $LOG 2>&1
        	if [ $? -eq 0 ]
        	then
        		printf " #"
        	else
        		printf " X"
        		return -1
        	fi
        done
 }
        	
 run_prepare_script()
 {
 	local IMAGE_SPEC=$1
        
        local IMAGE_MP=`$IMAGEINFO getImageMountPoint -f $IMAGE_SPEC`
        local PREPARE_SCRIPT=`$IMAGEINFO getImagePreparationScriptName -f $IMAGE_SPEC`
        if [ -n "$PREPARE_SCRIPT" ]
        then
		local FILE=`basename $PREPARE_SCRIPT`
 		echo Running: $FILE
		echo $CHROOT $MOUNT_POINT $TOOLS/env -i HOME=/ \
		        TERM=$TERM PATH=/usr/bin:/bin:$TOOLS $IMAGE_MP/$FILE prepare
		$CHROOT $MOUNT_POINT $TOOLS/env -i HOME=/ \
		TERM=$TERM PATH=/usr/bin:/bin:$TOOLS $IMAGE_MP/$FILE prepare
	fi
}

main $@
