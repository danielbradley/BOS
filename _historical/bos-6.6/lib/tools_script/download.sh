#
#  Included into tools scripts
#  Assumes that RESOURCE_URL and PKG_DIR
#  are defined

download()
{
	local File=$1
	local Url=${RESOURCE_URL}/${PKG_DIR}/${File}

	mkdir -p ${SOURCE} &&
	cd ${SOURCE} &&
	if [ ! -f ${File} ]
	then
		wget ${Url}
	fi
}
