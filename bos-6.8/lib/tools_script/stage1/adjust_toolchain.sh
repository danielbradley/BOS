#!/bin/bash
#
#       Copyright (c) 2004-2006 Daniel Robert Bradley. All rights reserved.
#

SOURCE=$BUILD_BASE/tools/source		# Where source packages are located
BUILD_DIR=$BUILD_BASE/tools/stage1	# Where this package should be built

PACKAGE=binutils		# Package information
VERSION=2.15.94.0.2.2		# Version information

GNU_PREFIX=/tools		# Prefix packages are installed into

#CHOST=i386-pc-linux-gnu

main()
{
	echo Adjust toolchain

	reinstall_binutils &&
	edit_gcc_specs &&
	remove_stuff &&
	echo done
}

reinstall_binutils()
{
	if [ ! -f $BUILD_DIR/ADJUSTED_BINUTILS ]
	then
		cd $BUILD_DIR/$PACKAGE-build
		make -C ld clean &&
		make -C ld LIB_PATH=/tools/lib &&
		make -C ld install &&
		touch $BUILD_DIR/ADJUSTED_BINUTILS
		rm -rf $BUILD_DIR/$PACKAGE-$VERSION/*
		rm -rf $BUILD_DIR/$PACKAGE-build/*
	fi
}

edit_gcc_specs()
{
	if [ ! -f $BUILD_DIR/ADJUSTED_GCC ]
	then
		# Need to handle both cases:
		# a) building from LFS
		# b) building from SZT

		SPECFILE=`gcc --print-file specs` &&
		sed 's@ /lib/ld-linux.so.2@ /tools/lib/ld-linux.so.2@g' \
			$SPECFILE > tempspecfile &&
		mv -f tempspecfile $SPECFILE &&
		sed 's@ /system/software/lib/ld-linux.so.2@ /tools/lib/ld-linux.so.2@g' \
			$SPECFILE > tempspecfile &&
		mv -f tempspecfile $SPECFILE &&
		unset SPECFILE
		touch $BUILD_DIR/ADJUSTED_GCC
	fi
}

remove_stuff()
{
	if [ ! -f $BUILD_DIR/REMOVED_STUFF ]
	then
		rm -vf /tools/lib/gcc/*/*/include/{pthread.h,bits/sigthread.h}
		touch $BUILD_DIR/REMOVED_STUFF
	fi
}

local HERE=`pwd`
main $@
cd $HERE
