#!/bin/bash -e

# This script requires:
#  - Packer
#  - jq (JSON CLI tool)
#  - QEMU tools
#  - OpenStack credentials loaded in your environment

if [ -z "${OS_USERNAME}" ]; then
    echo "Please load the OpenStack credentials"
    exit 1
fi

# Packer is dumb! See notes on OpenStack Authorization at:
#   https://www.packer.io/docs/builders/openstack.html
export OS_TENANT_NAME=$OS_PROJECT_NAME
export OS_DOMAIN_NAME=$OS_PROJECT_DOMAIN_NAME

# Find packer
if which packer >/dev/null 2>&1; then
    PACKER=packer
elif which packer-io >/dev/null 2>&1; then
    PACKER=packer-io
else
    echo "You need packer installed to use this tool"
    exit 1
fi

FILE=r-studio
NAME=$(jq -r '.builders[0].image_name' ${FILE}.json)
BUILD_NUMBER=$(date "+%Y%m%d%H%M")
BUILD_NAME="${FILE}_build_${BUILD_NUMBER}"

# Hard coded NeCTAR Ubuntu 16.04 for now
SOURCE_ID=$(openstack image list --limit 100 --long -f value -c ID -c Project --property 'name=NeCTAR Ubuntu 16.04 LTS (Xenial) amd64 (pre-installed murano-agent)' | grep 1fe7dcac580443a4818d10d18151e42f | cut -d' ' -f1)

# Update the name to include build number
#jq ".builders[0].source_image = \"${SOURCE_ID}\" | .builders[0].image_name = \"${BUILD_NAME}\" | .builders[0].tenant_name = \"${OS_PROJECT_NAME}\"" ${FILE}.json > /tmp/${BUILD_NAME}_packer.json
jq ".builders[0].source_image = \"${SOURCE_ID}\" | .builders[0].image_name = \"${BUILD_NAME}\"" ${FILE}.json > /tmp/${BUILD_NAME}_packer.json

echo "Building image ${NAME}..."
${PACKER} build /tmp/${BUILD_NAME}_packer.json
rm /tmp/${BUILD_NAME}_packer.json

openstack image save --file ${BUILD_NAME}_large.qcow2 ${BUILD_NAME}
openstack image delete ${BUILD_NAME}

echo "Shrinking image..."
qemu-img convert -c -o compat=0.10 -O qcow2 ${BUILD_NAME}_large.qcow2 ${BUILD_NAME}.qcow2
rm ${BUILD_NAME}_large.qcow2

if [ "${BUILD_PROPERTY}" != "" ] ; then
    GLANCE_ARGS="--property ${BUILD_PROPERTY}=${BUILD_NUMBER}"
fi

if [ "${MAKE_PUBLIC}" == "true" ] ; then
    GLANCE_ARGS="--public ${GLANCE_ARGS}"
fi

echo "Creating image \"${NAME}\"..."
IMAGE_ID=$(openstack image create -f value -c id --disk-format qcow2 --container-format bare --file ${BUILD_NAME}.qcow2 ${GLANCE_ARGS} $EXTRA_ARGS "${NAME}")
echo "Image ID: ${IMAGE_ID}"
rm ${BUILD_NAME}.qcow2
