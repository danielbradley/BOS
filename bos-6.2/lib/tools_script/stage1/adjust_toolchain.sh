#!/bin/bash
#
#       Copyright (c) 2004-2006 Daniel Robert Bradley. All rights reserved.
#

SOURCE=$BUILD_BASE/tools/source		# Where source packages are located
BUILD_DIR=$BUILD_BASE/tools/stage1	# Where this package should be built

PACKAGE=binutils		# Package information
VERSION=2.16.1			# Version information

GNU_PREFIX=/tools		# Prefix packages are installed into

#CHOST=i386-pc-linux-gnu

main()
{
	echo Adjust toolchain using path: $PATH
	reinstall_binutils   &&
	edit_gcc_specs       &&
	clean_fixed_includes &&
	#remove_stuff &&
	echo done
}

reinstall_binutils()
{
	local machine=`gcc -dumpmachine`

	if [ -z "$machine" ]
	then
		echo "Invalid machine type returned from gcc"
		return -1

	elif [ ! -f $BUILD_DIR/ADJUSTED_BINUTILS ]
	then
		mv -v  /tools/bin/{ld,ld-old}          &&
		mv -v  /tools/$machine/bin/{ld,ld-old} &&
		mv -v  /tools/bin/{ld-new,ld}          &&
		ln -sv /tools/bin/ld /tools/$machine/bin/ld

		touch $BUILD_DIR/ADJUSTED_BINUTILS
	fi
}

edit_gcc_specs()
{
	if [ ! -f $BUILD_DIR/ADJUSTED_GCC ]
	then

		local LIBGCC_FILE_NAME=`/tools/bin/gcc -print-libgcc-file-name`
	
		if [ "/tools/lib" != "${LIBGCC_FILE_NAME:0:10}" ]
		then
			echo "Error: /tools/bin/gcc is reporting incorrect libgcc-file-name"
			return -1

		else
			local SPECFILEDIR=`dirname ${LIBGCC_FILE_NAME}`
			local SPECFILE="$SPECFILEDIR/specs"

			if [ "/tools/lib/gcc/i686-pc-linux-gnu/4.0.3/specs" != "$SPECFILE" ]
			then
				echo "Error: SPECFILE is wrong: $SPECFILE"
				return -1
			else

				# Need to handle both cases:
				# a) building from LFS
				# b) building from SZT

				echo "Creating gcc specs file: $SPECFILE"
				gcc -dumpspecs                                                          > $SPECFILE &&
				sed -i 's@^/system/software/lib/ld-linux.so.2@/tools/lib/ld-linux.so.2@g' $SPECFILE &&
				sed -i                 's@^/lib/ld-linux.so.2@/tools/lib/ld-linux.so.2@g' $SPECFILE &&
				cp $SPECFILE /local/bos/target/log/specs                                            &&
				unset LIBGCC_FILE_NAME SPECFILEDIR SPECFILE                                         &&


				if [ ! -f "/tools/lib/gcc/i686-pc-linux-gnu/4.0.3/specs" ]
				then
					echo "Error: SPECFILE is missing: $SPECFILE"
					return -1
				else
					touch $BUILD_DIR/ADJUSTED_GCC
				fi
			fi
		fi
	fi
}

clean_fixed_includes()
{
	if [ ! -f "$BUILD_DIR/CLEAN_FIXED_INCLUDES" ]
	then
		GCC_INCLUDEDIR=`dirname $(gcc -print-libgcc-file-name)`/include     &&
		find ${GCC_INCLUDEDIR}/* -maxdepth 0 -xtype d -exec rm -rvf '{}' \; &&
		rm -vf `grep -l "DO NOT EDIT THIS FILE" ${GCC_INCLUDEDIR}/*`        &&
		unset GCC_INCLUDEDIR                                                &&

		touch $BUILD_DIR/CLEAN_FIXED_INCLUDES
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
