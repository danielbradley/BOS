#!/tools/software/bin/bash
#
#       Copyright (c) 2004-2006 Daniel Robert Bradley. All rights reserved.
#

GNU_BASE=/system/software/commands
CATEGORY=development
PACKAGE=gcc-3.3.1
DNAME=gnu-3.3.1

SOURCE=/mnt/source
BUILD_DIR=/mnt/build/toolchain

CHOST=i386-pc-linux-gnu

#  Executables used
GREP=/tools/software/bin/grep
TOUCH=/tools/software/bin/touch
RM=/tools/software/bin/rm

main()
{
#	unpack_package
#	apply_patches
#	configure_source
#	compile_source
#	install_package
	complete
}

unpack_package()
{
	if [ ! -d $BUILD_DIR/gcc-3.3.1 ]
	then
		tar -C $BUILD_DIR -jxvf $SOURCE/gcc-3.3.1.tar.bz2
	fi
}

apply_patches()
{
	if [ -f $BUILD_DIR/gcc-3.3.1/configure ]
	then
		if [ ! -f $BUILD_DIR/gcc-3.3.1/SUCCESS.PATCH ]
		then
			cd $BUILD_DIR/gcc-3.3.1 &&
			patch -Np1 -i $SOURCE/gcc-3.3.1-no_fixincludes-2.patch &&
			patch -Np1 -i $SOURCE/gcc-3.3.1-sysinc-2.patch &&
			patch -Np1 -i $SOURCE/gcc-3.3.1-caserospecs-1.patch &&
			touch $BUILD_DIR/gcc-3.3.1/SUCCESS.PATCH
		fi
	fi
}

configure_source()
{
	if [ -f $BUILD_DIR/gcc-3.3.1/configure ]
	then

		if [ ! -f $BUILD_DIR/gcc-build/config.cache ]
		then
			mkdir -p $BUILD_DIR/gcc-build &&
			cd $BUILD_DIR/gcc-build &&
			CFLAGS="-march=i386" CXXFLAGS="-march=i386" \
				../gcc-3.3.1/configure \
				--prefix=$GNU_BASE/$CATEGORY/$DNAME \
				--with-local-prefix=/local/software \
				--enable-languages=c,c++ \
				--enable-shared \
				--enable-threads=posix \
				--enable-__cxa_atexit \
				--enable-clocale=gnu \
				--host=$CHOST --target=$CHOST
		fi
	fi
}

compile_source()
{
	if [ -f $BUILD_DIR/gcc-build/config.cache ]
	then
		if [ ! -f $BUILD_DIR/gcc-build/gcc/xgcc ]
		then
			cd $BUILD_DIR/gcc-build
			make LDFLAGS="-Wl,--dynamic-linker,/system/software/lib/ld-linux.so.2"
		fi
	fi
}

install_package()
{
	if [ -f $BUILD_DIR/gcc-build/gcc/xgcc ]
	then
		if [ ! -f $GNU_BASE/$CATEGORY/$DNAME/bin/gcc ]
		then
			cd $BUILD_DIR/gcc-build &&
			make install
#			mkdir -p /system/software/libraries/gnu/g++-3.3.1/lib &&
#                        cp /system/software/Applications/development/gnu-3.3.1/lib/libstdc++* \
#                                /system/software/libraries/gnu/g++-3.3.1/lib &&
			ln -s gcc $GNU_BASE/$CATEGORY/$DNAME/bin/cc
		fi
	fi
}

complete()
{
	if [ -f $GNU_BASE/$CATEGORY/$DNAME/bin/gcc ]
	then
		rm -rf $BUILD_DIR/gcc-3.3.1/*
		rm -rf $BUILD_DIR/gcc-build/*
	fi
}

main $@

