#!/bin/bash
#
#       Copyright (c) 2004-2006 Daniel Robert Bradley. All rights reserved.
#

SOURCE=$BUILD_BASE/tools/source	# Where source packages are located
BUILD=$BUILD_BASE/tools/ted		# Where this package should be built

PACKAGE=tcl						# Package information
VERSION=8.4.9					# Version information

GNU_PREFIX=/tools		# Prefix packages are installed into

#CHOST=i386-pc-linux-gnu

ARCHIVE=tar.bz2
PKG_DIR=core/commands

main()
{
	echo $PACKAGE-$VERSION

	download ${PACKAGE}${VERSION}-src.${ARCHIVE} &&
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
	if [ ! -d $BUILD/$PACKAGE$VERSION ]
	then
		mkdir -p $BUILD
		tar -C $BUILD -jxvf $SOURCE/$PACKAGE$VERSION-src.tar.bz2
	fi
}

apply_patches()
{
	if [ -f $BUILD/$PACKAGE$VERSION/README ]
	then
		if [ ! -f $BUILD/$PACKAGE$VERSION/SUCCESS.PATCHED ]
		then
			cd $BUILD/$PACKAGE$VERSION
			touch $BUILD/$PACKAGE$VERSION/SUCCESS.PATCHED
		fi
	fi
}

configure_source()
{
	if [ -f $BUILD/$PACKAGE$VERSION/SUCCESS.PATCHED ]
	then
		if [ ! -f $BUILD/$PACKAGE$VERSION/SUCCESS.CONFIGURE ]
		then
			cd $BUILD/$PACKAGE$VERSION/unix &&
#			CFLAGS="-march=i386"
			./configure --prefix=$GNU_PREFIX
#				--host=$CHOST --target=$CHOST &&
			touch /$BUILD/$PACKAGE$VERSION/SUCCESS.CONFIGURE
		fi
	fi
}

compile_source()
{
	if [ -f $BUILD/$PACKAGE$VERSION/SUCCESS.CONFIGURE ]
	then
		if [ ! -f $BUILD/$PACKAGE$VERSION/SUCCESS.MAKE ]
		then
			cd $BUILD/$PACKAGE$VERSION/unix &&
			make &&
			touch $BUILD/$PACKAGE$VERSION/SUCCESS.MAKE
		fi
	fi
}

install_package()
{
	if [ -f $BUILD/$PACKAGE$VERSION/SUCCESS.MAKE ]
	then
		if [ ! -f $BUILD/$PACKAGE$VERSION/SUCCESS.INSTALL ]
		then
			cd $BUILD/$PACKAGE$VERSION/unix &&
			make install &&
			touch $BUILD/$PACKAGE$VERSION/SUCCESS.INSTALL
		fi
	fi
}

complete()
{
	if [ -f $BUILD/$PACKAGE$VERSION/SUCCESS.INSTALL ]
	then
		return 0 # Is deleted by expect
#		rm -rf $BUILD/$PACKAGE$VERSION/*
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
