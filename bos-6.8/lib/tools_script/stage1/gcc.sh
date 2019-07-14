#!/bin/bash
#
#       Copyright (c) 2004-2006 Daniel Robert Bradley. All rights reserved.
#

SOURCE=$BUILD_BASE/tools/source		# Where source packages are located
BUILD_DIR=$BUILD_BASE/tools/stage1	# Where this package should be built

PACKAGE=gcc							# Package information
VERSION=4.5.2						# Version information

MPF="mpfr-3.0.0.tar.bz2"
GMP="gmp-5.0.1.tar.bz2 "
MPC="mpc-0.8.2.tar.gz"


GNU_PREFIX=/tools					# Prefix packages are installed into
LFS_TGT=$(uname -m)-lfs-linux-gnu

#CHOST=i386-pc-linux-gnu

ARCHIVE=tar.bz2
PKG_DIR=core/toolchain

main()
{
	echo $PACKAGE-$VERSION

	download ${PACKAGE}-${VERSION}.${ARCHIVE} &&
	download $MPF    &&
	download $GMP    &&
	download $MPC    &&
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
		mkdir -p $BUILD_DIR                                       &&
		tar -C $BUILD_DIR -jxvf $SOURCE/$PACKAGE-$VERSION.tar.bz2 &&
		tar -C $BUILD_DIR -jxvf $SOURCE/$MPF                      &&
		tar -C $BUILD_DIR -jxvf $SOURCE/$GMP                      &&
		tar -C $BUILD_DIR -zxvf $SOURCE/$MPC                      &&
		mv -v $MPF mpfr                                           &&
		mv -v $GMP gmp                                            &&
		mv -v $MPC mpc
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
#			../$PACKAGE-$VERSION/configure \
#				--target=$LFS_TGT \
#				--prefix=$GNU_PREFIX       \
#				--libexecdir=/tools/lib    \
#				--with-local-prefix=/tools \
#				--disable-nls              \
#				--enable-shared            \
#				--enable-languages=c       \
#				# new
#				--disable-multilib         \
#				--disable-decimal-float    \
#				--disable-threads          \
#				--disable-libmudflap       \
#				--disable-libssp           \
#				--disable-libgomp          \
#				--without-ppl              \
#				--without-cloog &&

			../$PACKAGE-$VERSION/configure \
				--target=$LFS_TGT \
				--prefix=$GNU_PREFIX       \
				--disable-nls              \
				--disable-shared           \
				--disable-multilib         \
				--disable-decimal-float    \
				--disable-threads          \
				--disable-libmudflap       \
				--disable-libssp           \
				--disable-libgomp          \
				--enable-languages=c       \
				--without-ppl              \
				--without-cloog &&

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
