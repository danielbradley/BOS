#!/bin/bash
#
#       Copyright (c) 2004-2006 Daniel Robert Bradley. All rights reserved.
#

SOURCE=$BUILD_BASE/tools/source		# Where source packages are located
BUILD_DIR=$BUILD_BASE/tools/stage1	# Where this package should be built

PACKAGE=gcc				# Package information
VERSION=12.2.0			# Version information

GNU_PREFIX=/tools		# Prefix packages are installed into

MACHINE=`uname -m`
TARGET=$MACHINE-szt-linux-gnu

#CHOST=i386-pc-linux-gnu

ARCHIVE=tar.xz
PKG_DIR=core/toolchain

main()
{
	echo $PACKAGE-$VERSION

	download ${PACKAGE}-${VERSION}.${ARCHIVE} &&
	download mpfr-4.2.0.tar.xz                &&
	download gmp-6.2.1.tar.xz                 &&
	download mpc-1.3.1.tar.gz                 &&
	unpack_package                            &&
	apply_patches                             &&
	configure_source                          &&
	compile_source                            &&
	install_package                           &&
	complete                                  &&
	echo done
}

unpack_package()
{
	if [ ! -d $BUILD_DIR/$PACKAGE-$VERSION ]
	then
		mkdir -p $BUILD_DIR                                         &&
		tar -C $BUILD_DIR -xvf $SOURCE/$PACKAGE-$VERSION.${ARCHIVE} &&
		tar -C $BUILD_DIR/$PACKAGE-$VERSION -xvf mpfr-4.2.0.tar.xz  &&
		tar -C $BUILD_DIR/$PACKAGE-$VERSION -xvf gmp-6.2.1.tar.xz   &&
		tar -C $BUILD_DIR/$PACKAGE-$VERSION -xvf mpc-1.3.1.tar.xz   &&

		mv $BUILD_DIR/$PACKAGE-$VERSION/mpfr-4.2.0 \
		   $BUILD_DIR/$PACKAGE-$VERSION/mpfr                        &&

		mv $BUILD_DIR/$PACKAGE-$VERSION/gmp-6.2.1 \
		   $BUILD_DIR/$PACKAGE-$VERSION/gmp                         &&

		mv $BUILD_DIR/$PACKAGE-$VERSION/mpc-1.3.1 \
		   $BUILD_DIR/$PACKAGE-$VERSION/mpc

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
			cd $BUILD_DIR/$PACKAGE-build       &&

			../$PACKAGE-$VERSION/configure    \
				--target=$TARGET              \
				--prefix=$GNU_PREFIX          \
				--with-glibc-version=2.37     \
				--with-sysroot=/              \
				--libexecdir=/tools/lib       \
				--with-local-prefix=/tools    \
				--with-newlib                 \
				--without-headers             \
				--enable-default-pie          \
				--enable-default-ssp          \
				--disable-nls                 \
				--disable-shared              \
				--disable-multilib            \
				--disable-threads             \
				--disable-libatomic           \
				--disable-libgomp             \
				--disable-libquadmath         \
				--disable-libssp              \
				--disable-libvtv              \
				--disable-libstdcxx           \
				--enable-languages=c,c++       &&

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
