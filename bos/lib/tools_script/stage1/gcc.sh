#!/bin/bash
#
#       Copyright (c) 2004-2006 Daniel Robert Bradley. All rights reserved.
#

SOURCE=$BUILD_BASE/tools/source		# Where source packages are located
BUILD_DIR=$BUILD_BASE/tools/stage1	# Where this package should be built

PACKAGE=gcc			# Package information
VERSION=3.4.3			# Version information

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
	fi
}

apply_patches()
{
	if [ -f $BUILD_DIR/$PACKAGE-$VERSION/README ]
	then
		if [ ! -f $BUILD_DIR/$PACKAGE-$VERSION/SUCCESS.PATCHED ]
		then
			cd $BUILD_DIR/$PACKAGE-$VERSION
			sed -i 's@/lib/ld-linux.so.2@/system/software/lib/ld-linux.so.2@g' \
				`grep -r -l "ld-linux" *` &&
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
			mkdir -p $BUILD_DIR/$PACKAGE-build &&
			cd $BUILD_DIR/$PACKAGE-build &&

#			CFLAGS="-march=i386"
			../$PACKAGE-$VERSION/configure \
				--prefix=$GNU_PREFIX \
				--libexecdir=/tools/lib \
				--with-local-prefix=/tools \
				--disable-nls --enable-shared \
				--enable-languages=c
#				--host=$CHOST --target=$CHOST &&
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
			cd $BUILD_DIR/$PACKAGE-build &&
			make bootstrap &&
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
			cd $BUILD_DIR/$PACKAGE-build &&
			make install &&
			ln -s gcc /tools/bin/cc &&
			touch $BUILD_DIR/$PACKAGE-$VERSION/SUCCESS.INSTALL
		fi
	fi
}

complete()
{
	if [ -f $BUILD_DIR/$PACKAGE-$VERSION/SUCCESS.INSTALL ]
	then
		rm -rf $BUILD_DIR/$PACKAGE-$VERSION/*
		rm -rf $BUILD_DIR/$PACKAGE-build/*
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
