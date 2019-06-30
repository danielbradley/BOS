#!/bin/bash
#
#       Copyright (c) 2004-2006 Daniel Robert Bradley. All rights reserved.
#
#  Usage 9_FinishImages.sh <directory> <target>

main()
{
	ProjectFile="$1"

	find_base_dir $@
	read_headers $@
	process_arguments $@ &&

	populate_ISO_directory &&
	unmount_images &&
	squash_images &&
	create_iso_image &&
	remount_images ${ProjectFile}
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

populate_ISO_directory()
{
	local     Iso=${TARGET}/ISO
	local    Grub=${TARGET}/ISO/boot/grub
	local Kernels=${TARGET}/ISO/Securizant/kernels
	local  Images=${TARGET}/ISO/Securizant/${EDITION}/${RELEASE}

	mkdir -p ${Iso}
	mkdir -p ${Grub}
	mkdir -p ${Kernels}
	mkdir -p ${Images}

	cp ${MOUNT_POINT}/system/software/kernels/linux* ${Kernels}
	cp ${MOUNT_POINT}/system/software/commands/utils/grub-*/lib/grub/i386-pc/stage2_eltorito ${Grub}
	cp ${MOUNT_POINT}/system/startup/configuration/menu.lst ${Grub}
}

unmount_images()
{
	${BASE_DIR}/bin/unmount ${TARGET}	
	echo "Unmounted images"
}

squash_images()
{
	echo "Squashing: ${TARGET}"
	for E2File in ${TARGET}/*.e2
	do
		local File=`basename ${E2File} .e2`
		if [ "${File}" != "build" ]
		then
			squash_image ${File}
		fi
	done
}

squash_image()
{
	local    File=$1
	local     Iso=${TARGET}/ISO
	local    Grub=${TARGET}/ISO/boot/grub
	local Kernels=${TARGET}/ISO/Securizant/kernels
	local  Images=${TARGET}/ISO/Securizant/${EDITION}/${RELEASE}

	mkdir -p ${TARGET}/mnt
	mount ${TARGET}/${File}.e2 ${TARGET}/mnt -o loop,ro
	mksquashfs ${TARGET}/mnt ${Images}/${File}.img -noappend
	umount -d ${TARGET}/mnt
	rmdir ${TARGET}/mnt
}

create_iso_image()
{
	cd ${TARGET}
	mkisofs -R -b boot/grub/stage2_eltorito -no-emul-boot -boot-load-size 4 -boot-info-table -o Securizant_${EDITION}-${RELEASE}.iso ISO
}

remount_images()
{
	local ProjectFile="$1"
	${BASE_DIR}/bin/bos_mount ${ProjectFile}
}

main $@
