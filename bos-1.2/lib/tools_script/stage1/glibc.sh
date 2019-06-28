#!/bin/bash
#
#       Copyright (c) 2004-2006 Daniel Robert Bradley. All rights reserved.
#

SOURCE=$BUILD_BASE/tools/source		# Where source packages are located
BUILD_DIR=$BUILD_BASE/tools/stage1	# Where this package should be built

PACKAGE=glibc			# Package information
VERSION=2.3.4			# Version information

GNU_PREFIX=/tools		# Prefix packages are installed into

#CHOST=i386-pc-linux-gnu

ARCHIVE=tar.bz2
PKG_DIR=core/toolchain

main()
{
	echo $PACKAGE-$VERSION

	download ${PACKAGE}-${VERSION}.${ARCHIVE} &&
	download ${PACKAGE}-${VERSION}-fix_test-1.patch &&
	download ${PACKAGE}-${VERSION}-rtld_search_dirs-1.patch &&
	download ${PACKAGE}-${VERSION}-tls_assert-1.patch &&
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
			patch -Np1 -i $SOURCE/$PACKAGE-$VERSION-fix_test*.patch

			sed -i 's@/etc@/tools/etc@g' sysdeps/unix/sysv/linux/paths.h
			
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

#			CFLAGS="-march=i386 -O2"
			../$PACKAGE-$VERSION/configure \
				--prefix=$GNU_PREFIX \
				--disable-profile --enable-add-ons \
				--enable-kernel=2.6.0 \
				--with-binutils=/tools/bin \
				--without-gd --with-headers=/tools/include \
				--without-selinux \
				--sysconfdir=$GNU_PREFIX/etc
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
			cd $BUILD_DIR/$PACKAGE-build &&
			mkdir -v $GNU_PREFIX/etc
			touch $GNU_PREFIX/etc/ld.so.conf
			echo "111.125.177.87 www.securizant.org" > $GNU_PREFIX/etc/hosts
			cp $PROJECT_DIR/resources/static/default_settings/2008/users/passwd $GNU_PREFIX/etc/passwd
			make install &&
			touch $BUILD_DIR/$PACKAGE-$VERSION/SUCCESS.INSTALL
		fi
	fi
}

complete()
{
	if [ -f $BUILD_DIR/$PACKAGE-$VERSION/SUCCESS.INSTALL ]
	then
		echo
#		rm -rf $BUILD_DIR/$PACKAGE-$VERSION/*
#		rm -rf $BUILD_DIR/$PACKAGE-build/*
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
