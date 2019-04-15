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

FILE=packer
NAME=$(jq -r '.builders[0].image_name' ${FILE}.json)
BUILD_NUMBER=$(date "+%Y%m%d%H%M")
BUILD_NAME="${FILE}_build_${BUILD_NUMBER}"

# Get the latest Bionic Murano image
IMAGE_NAME='NeCTAR Ubuntu 18.04 LTS (Bionic) amd64 (pre-installed murano-agent)'
SOURCE_ID=$(openstack image show -f value -c id "$IMAGE_NAME")

# Update the name to include build number
jq ".builders[0].source_image = \"${SOURCE_ID}\" | .builders[0].image_name = \"${BUILD_NAME}\"" ${FILE}.json > /tmp/${BUILD_NAME}_packer.json

echo "Building image ${NAME}..."
packer build /tmp/${BUILD_NAME}_packer.json
rm /tmp/${BUILD_NAME}_packer.json

openstack image save --file ${BUILD_NAME}_large.qcow2 ${BUILD_NAME}
openstack image delete ${BUILD_NAME}

echo "Shrinking image..."
qemu-img convert -c -o compat=0.10 -O qcow2 ${BUILD_NAME}_large.qcow2 ${BUILD_NAME}.qcow2
rm ${BUILD_NAME}_large.qcow2

# Base properties
GLANCE_ARGS='--property architecture=x86_64 --property os_distro=ubuntu --property os_version=18.04'

# QEMU Guest Agent is installed
GLANCE_ARGS="--property hw_qemu_guest_agent=yes ${GLANCE_ARGS}"

# Discover facts to set as image properties
FACT_DIR=ansible/.facts
for FACT in $(ls $FACT_DIR); do
    VAL=$(cat $FACT_DIR/$FACT)
    GLANCE_ARGS="--property ${FACT}=${VAL} ${GLANCE_ARGS}"
done

echo "Creating image \"${NAME}\"..."
IMAGE_ID=$(openstack image create -f value -c id --disk-format qcow2 --container-format bare --file ${BUILD_NAME}.qcow2 ${GLANCE_ARGS} "${NAME}")
echo "Image ID: ${IMAGE_ID}"
rm ${BUILD_NAME}.qcow2
