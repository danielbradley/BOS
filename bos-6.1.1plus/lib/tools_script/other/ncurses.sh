#!/bin/bash
#
#       Copyright (c) 2004-2006 Daniel Robert Bradley. All rights reserved.
#

SOURCE=$BUILD_BASE/tools/source		# Where source packages are located
BUILD=$BUILD_BASE/tools/other	# Where this package should be built

PACKAGE=ncurses			# Package information
VERSION=5.5				# Version information

GNU_PREFIX=/tools		# Prefix packages are installed into

#CHOST=i386-pc-linux-gnu

ARCHIVE=tar.gz
PKG_DIR=core/libraries

main()
{
	echo $PACKAGE-$VERSION

	download ${PACKAGE}-${VERSION}.${ARCHIVE} &&
	unpack_package &&
	apply_patches &&
	configure_source &&
	compile_source &&
	install_package &&
	delete_package &&
	echo done
}

unpack_package()
{
	if [ ! -d $BUILD/$PACKAGE-$VERSION ]
	then
		mkdir -p $BUILD &&
		tar -C $BUILD -zxvf $SOURCE/$PACKAGE-$VERSION.tar.bz2
	fi
}

apply_patches()
{
	if [ -f $BUILD/$PACKAGE-$VERSION/README ]
	then
		if [ ! -f $BUILD/$PACKAGE-$VERSION/SUCCESS.PATCHED ]
		then
			cd $BUILD/$PACKAGE-$VERSION &&
			touch $BUILD/$PACKAGE-$VERSION/SUCCESS.PATCHED
		fi
	fi
}

configure_source()
{
	if [ -f $BUILD/$PACKAGE-$VERSION/SUCCESS.PATCHED ]
	then
		if [ ! -f $BUILD/$PACKAGE-$VERSION/SUCCESS.CONFIGURE ]
		then
			cd $BUILD/$PACKAGE-$VERSION &&

#			CFLAGS="-march=i386"
			./configure \
				--prefix=$GNU_PREFIX \
				--with-shared \
				--without-debug \
				--without-ada \
				--enable-overwrite
#				--host=$CHOST --target=$CHOST &&
			touch /$BUILD/$PACKAGE-$VERSION/SUCCESS.CONFIGURE
		fi
	fi
}

compile_source()
{
	if [ -f $BUILD/$PACKAGE-$VERSION/SUCCESS.CONFIGURE ]
	then
		if [ ! -f $BUILD/$PACKAGE-$VERSION/SUCCESS.MAKE ]
		then
			cd $BUILD/$PACKAGE-$VERSION &&
			make &&
			touch $BUILD/$PACKAGE-$VERSION/SUCCESS.MAKE
		fi
	fi
}

install_package()
{
	if [ -f $BUILD/$PACKAGE-$VERSION/SUCCESS.MAKE ]
	then
		if [ ! -f $BUILD/$PACKAGE-$VERSION/SUCCESS.INSTALL ]
		then
			cd $BUILD/$PACKAGE-$VERSION &&
			make install &&
			touch $BUILD/$PACKAGE-$VERSION/SUCCESS.INSTALL
		fi
	fi
}

delete_package()
{
	if [ -f $BUILD/$PACKAGE-$VERSION/SUCCESS.INSTALL ]
	then
		rm -rf $BUILD/$PACKAGE-$VERSION/*
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
