#!/bin/bash
#
#       Copyright (c) 2004-2006 Daniel Robert Bradley. All rights reserved.
#

SOURCE=$BUILD_BASE/tools/source		# Where source packages are located
BUILD_DIR=$BUILD_BASE/tools/stage1	# Where this package should be built

PACKAGE=linux-libc-headers	# Package information
VERSION=2.6.11.2		# Version information

GNU_PREFIX=/tools		# Prefix packages are installed into

#CHOST=i386-pc-linux-gnu

ARCHIVE=tar.bz2
PKG_DIR=core/toolchain

main()
{
	echo $PACKAGE-$VERSION

	download ${PACKAGE}-${VERSION}.${ARCHIVE} &&
	unpack_package &&
	apply_patches &&
	configure_source &&
	compile_source &&
	install_package &&
	complete &&
	echo done
}

unpack_package()
{
	if [ ! -d $BUILD_DIR/$PACKAGE-$VERSION ]
	then
		mkdir -p $BUILD_DIR
		tar -C $BUILD_DIR -jxvf $SOURCE/$PACKAGE-$VERSION.tar.bz2
		cd $BUILD_DIR/$PACKAGE-$VERSION
		cp -Rv include/asm-i386 $GNU_PREFIX/include/asm
		cp -Rv include/linux $GNU_PREFIX/include/linux
		touch $BUILD_DIR/$PACKAGE-$VERSION/SUCCESS.INSTALL
	fi

}

complete()
{
	if [ -f $BUILD_DIR/$PACKAGE-$VERSION/SUCCESS.INSTALL ]
	then
		rm -rf $BUILD_DIR/$PACKAGE-$VERSION/*
	fi
}

premain()
{
	local Here=`pwd`
	main $@
	let ret=$?
	cd ${Here}
	return $ret
}

premain $@
