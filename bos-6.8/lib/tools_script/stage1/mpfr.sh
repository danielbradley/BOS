#!/bin/bash
#
#       Copyright (c) 2004-2006 Daniel Robert Bradley. All rights reserved.
#

SOURCE=$BUILD_BASE/tools/source		# Where source packages are located
BUILD_DIR=$BUILD_BASE/tools/stage1	# Where this package should be built

PACKAGE=mpfr						# Package information
VERSION=3.0.0						# Version information
ARCHIVE=tar.bz2

GNU_PREFIX=/tools					# Prefix packages are installed into

#CHOST=i386-pc-linux-gnu

PKG_DIR=core/toolchain

main()
{
	echo $PACKAGE-$VERSION

	download ${PACKAGE}-${VERSION}.${ARCHIVE} &&
	unpack_package   &&
	apply_patches    &&
	configure_source &&
	compile_source   &&
	install_package  &&
	complete         &&
	echo done
}

unpack_package()
{
	if [ ! -d $BUILD_DIR/$PACKAGE-$VERSION ]
	then
		mkdir -p $BUILD_DIR                                    &&
		tar -C $BUILD_DIR -jxvf $SOURCE/$PACKAGE-$VERSION.$ARCHIVE
	fi
}

apply_patches()
{
	if [ -f $BUILD_DIR/$PACKAGE-$VERSION/INSTALL ]
	then
		if [ ! -f $BUILD_DIR/$PACKAGE-$VERSION/SUCCESS.PATCHED ]
		then
			cd $BUILD_DIR/$PACKAGE-$VERSION
			touch $BUILD_DIR/$PACKAGE-$VERSION/SUCCESS.PATCHED
		fi
	fi
}

configure_source()
{
	if [ -f $BUILD_DIR/$PACKAGE-$VERSION/SUCCESS.PATCHED ]
	then
		if [ ! -f $BUILD_DIR/$PACKAGE-$VERSION/SUCCESS.CONFIGURE ]
		then
			cd $BUILD_DIR/$PACKAGE-$VERSION &&
			./configure \
				--with-gmp-include=$BUILD_DIR/gmp-5.0.1 \
				--with-gmp-lib=$BUILD_DIR/gmp-5.0.1/.libs &&
			touch /$BUILD_DIR/$PACKAGE-$VERSION/SUCCESS.CONFIGURE
		fi
	fi
}

compile_source()
{
	if [ -f $BUILD_DIR/$PACKAGE-$VERSION/SUCCESS.CONFIGURE ]
	then
		if [ ! -f $BUILD_DIR/$PACKAGE-$VERSION/SUCCESS.MAKE ]
		then
			cd $BUILD_DIR/$PACKAGE-$VERSION &&
			make &&
			touch $BUILD_DIR/$PACKAGE-$VERSION/SUCCESS.MAKE
		fi
	fi
}

install_package()
{
	if [ -f $BUILD_DIR/$PACKAGE-$VERSION/SUCCESS.MAKE ]
	then
		if [ ! -f $BUILD_DIR/$PACKAGE-$VERSION/SUCCESS.INSTALL ]
		then
			cd $BUILD_DIR/$PACKAGE-$VERSION &&
			touch $BUILD_DIR/$PACKAGE-$VERSION/SUCCESS.INSTALL
		fi
	fi
}

complete()
{
	if [ -f $BUILD_DIR/$PACKAGE-$VERSION/SUCCESS.INSTALL ]
	then
		rm $BUILD_DIR/$PACKAGE-$VERSION/INSTALL
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