#!/bin/bash
#
#       Copyright (c) 2004-2006 Daniel Robert Bradley. All rights reserved.
#
#  Mount images image
#
#  Usage 2_MountImages.sh <directory> <target>

main()
{
	local Exe="$0" &&
	local ProjectFile="$1" &&

	find_base_dir "${Exe}" &&
	read_headers "${ProjectFile}" &&
	process_arguments &&
	create_virtual_root_mountpoint #&&
	mount_root_image &&
	mount_images
}

find_base_dir()
{
	local Exe="$1"
	
        local ThisDir="$PWD"
        local ExeDir=`dirname "${Exe}"`
        cd "${ExeDir}/../.."
        BASE_DIR=`pwd`
        cd "${ThisDir}"
}

read_headers()
{
	local ProjectFile="$1"

	PROJECT_DIR=`dirname "${ProjectFile}"`
	source "${ProjectFile}"
        source "$BASE_DIR/etc/bos.conf"
	LOG="${TARGET}/log/mount.log"
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

	local TargetDirName=`basename "${TARGET}"` &&
	MOUNT_POINT="${VAR_DIR}/${NAMESPACE}/${TargetDirName}" &&
	TOOLS_MNT="${MOUNT_POINT}/tools"
}

create_virtual_root_mountpoint()
{
 #	printf "\t%s (%s)\n" "b) creating mount point" $MOUNT_POINT
	if [ ! -d "${MOUNT_POINT}" ]
	then
		printf "\tmkdir -p ${MOUNT_POINT}" >> "$LOG" 2>&1 &&
		mkdir -m 755 -p "${VAR_DIR}"
		mkdir -m 755 -p "${VAR_DIR}/${NAMESPACE}"		
		mkdir -m 755 -p "${MOUNT_POINT}"
		
	fi
}

#
#	Each image should:
#	a)	create its mount point
#	b)	mount itself
#	c)	then populate itself
#

mount_root_image()
{
#	Need to iterate through each IMAGE_SPEC, find the
#	root image and mount that first.

	for IMAGE_SPEC in $IMAGE_SPEC_DIR/*.spec
	do
		local IMAGE_MP=`$IMAGEINFO getImageMountPoint -f $IMAGE_SPEC`
		local IMAGE_SZ=`$IMAGEINFO getImageSize -f $IMAGE_SPEC`

		if [ -n "$IMAGE_SZ" -a "$IMAGE_MP" == "/" ]
		then
			mount_image $IMAGE_SPEC >> $LOG 2>&1
		fi
	done
}

mount_images()
{
	#	Mount images located on root file system

	for IMAGE_SPEC in $IMAGE_SPEC_DIR/*.spec
	do
		local IMAGE_MP=`$IMAGEINFO getImageMountPoint -f $IMAGE_SPEC`
		if [ $IMAGE_MP != "/" ]
		then
			local IMAGE_MP_DIRNAME=`dirname $IMAGE_MP`

			if [ $IMAGE_MP_DIRNAME == "/" ]
			then
				printf "$IMAGE_SPEC\n"  >> $LOG 2>&1
				mount_image $IMAGE_SPEC >> $LOG 2>&1
				if [ $? -eq 0 ]
				then
					printf " #"
				else
					printf " X"
					return -1
				fi
			fi
		fi
	done

	for IMAGE_SPEC in $IMAGE_SPEC_DIR/*.spec
	do
		local IMAGE_MP=`$IMAGEINFO getImageMountPoint -f $IMAGE_SPEC`
		if [ $IMAGE_MP != "/" ]
		then
			local IMAGE_MP_DIRNAME=`dirname $IMAGE_MP`

			if [ $IMAGE_MP_DIRNAME != "/" ]
			then
				printf "$IMAGE_SPEC\n"  >> $LOG 2>&1
				mount_image $IMAGE_SPEC >> $LOG 2>&1
				if [ $? -eq 0 ]
				then
					printf " #"
				else
					printf " X"
					return -1
				fi
			fi
		fi
	done
}

mount_image()
{
#	@param $1 image_spec 

#	Need to iterate through each IMAGE_SPEC and
#	mount each one as appropriate.
#
#
#

	local IMAGE_SPEC=$1

	local FLAGS=`$IMAGEINFO getImageMountFlags -f $IMAGE_SPEC`
	local FS_TYPE=`$IMAGEINFO getImageFilesystem -f $IMAGE_SPEC`

	local IMAGE_MP=`$IMAGEINFO getImageMountPoint -f $IMAGE_SPEC`
	local IMAGE_NAME=`$IMAGEINFO getImageName -f $IMAGE_SPEC`
	local IMAGE_MP_DIRNAME=`dirname $IMAGE_MP`
	local MOUNT_FLAGS=""
	
	if [ -n "$FLAGS" ]
	then
		MOUNT_FLAGS="-o $FLAGS"
	fi

	if [ "$IMAGE_MP" == "/tools" ]
	then
		IMAGE_NAME="../$TOOLS_IMAGE_NAME"
	fi

#	printf "2) Mounting image: %s\n" $IMAGE_NAME
#	printf "\t\tMounting %s --> %s\n" $TARGET/$IMAGE_NAME $MOUNT_POINT$IMAGE_MP

	mkdir -p ${MOUNT_POINT}${IMAGE_MP}

	if [ -d $MOUNT_POINT$IMAGE_MP ]
	then
#		printf "\t\t\tMount point exists: %s\n" $MOUNT_POINT$IMAGE_MP
	
		if [ ! -d $MOUNT_POINT$IMAGE_MP/lost+found -a ! -e $MOUNT_POINT$IMAGE_MP/self ]
		then
			local FIRST_CHAR=${IMAGE_NAME:0:1}
			local MOUNT_TYPE=""

			if [ -n "$FS_TYPE" ]
			then
				MOUNT_TYPE="-t $FS_TYPE"
			fi

			if [ "/" == "$FIRST_CHAR" ]
			then
				printf "\t$MOUNT -n $MOUNT_FLAGS $MOUNT_TYPE $IMAGE_NAME $MOUNT_POINT$IMAGE_MP\n"
				$MOUNT -n $MOUNT_FLAGS $MOUNT_TYPE $IMAGE_NAME $MOUNT_POINT$IMAGE_MP
				if [ $? = 0 ]
				then
					printf " (done)\n"
				else
					printf " (failed)\n"
				fi

			else
				printf "\t$MOUNT -n $MOUNT_FLAGS $MOUNT_TYPE $TARGET/$IMAGE_NAME $MOUNT_POINT$IMAGE_MP\n"
				$MOUNT -n $MOUNT_FLAGS $MOUNT_TYPE $TARGET/$IMAGE_NAME $MOUNT_POINT$IMAGE_MP
				if [ $? = 0 ]
				then
					printf " (done)\n"
				else
					printf " (failed)\n"
				fi
			fi

		else
			printf "\tAlready mounted: $IMAGE_MP ($IMAGE_NAME)\n"
		fi
	fi

	if [ -d $MOUNT_POINT$IMAGE_MP/lost+found ]
	then
		local PREPARE_SCRIPT=`$IMAGEINFO getImagePreparationScriptName -f $IMAGE_SPEC`

		create_directories $IMAGE_SPEC
#		create_links $IMAGE_SPEC
#
#		if [ -n "$PREPARE_SCRIPT" ]
#		then
#			if [ ! -f $MOUNT_POINT$IMAGE_MP/$PREPARE_SCRIPT ]
#			then
#				printf "\t	cp $RESOURCE_DIR/$PREPARE_SCRIPT $MOUNT_POINT$IMAGE_MP\n"
#				#cp $BASE_DIR/lib/resources/$PREPARE_SCRIPT $MOUNT_POINT$IMAGE_MP
#				cp $RESOURCE_DIR/$PREPARE_SCRIPT $MOUNT_POINT$IMAGE_MP
#				chmod a+x $MOUNT_POINT$IMAGE_MP/*.script
#			fi
#		fi
	fi
}

create_directories()
{
	local IMAGE_SPEC=$1
	local IMAGE_MP=`$IMAGEINFO getImageMountPoint -f $IMAGE_SPEC`
	local BASE=$MOUNT_POINT$IMAGE_MP
	local SUBDIRECTORIES=`$IMAGEINFO getSubdirectories -f $IMAGE_SPEC`

#	printf "\t\tCreating directores for: %s\n" $IMAGE_SPEC
#	printf "\t\t\tBase directory: %s\n" $BASE

	for DIRECTORY in $SUBDIRECTORIES
	do
		local DIR_SOURCE=`$IMAGEINFO getDirSource $DIRECTORY -f $IMAGE_SPEC`

#		echo mkdir -p $MOUNT_POINT/$IMAGE_MP/$DIRECTORY
		mkdir -p $MOUNT_POINT/$IMAGE_MP/$DIRECTORY
	done
}

main $@
