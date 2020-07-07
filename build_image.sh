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

# Set the AZ
AZ=melbourne-qh2
if echo $OS_AUTH_URL | grep -q test; then
    AZ=coreservices
fi

NAME=$(jq -r '.builders[0].image_name' packer.json)
BUILD_NUMBER=$(date "+%Y%m%d%H%M")
BUILD_NAME="packer_build_${BUILD_NUMBER}"
FACT_DIR=ansible/.facts
TAG_DIR=ansible/.tags
rm -fr $FACT_DIR $TAG_DIR

# Get the latest Bionic image
IMAGE_NAME='NeCTAR Ubuntu 18.04 LTS (Bionic) amd64'
SOURCE_ID=$(openstack image show -f value -c id "$IMAGE_NAME")
echo "Found base image $IMAGE_NAME ($SOURCE_ID)..."

# Update the name to include build number
jq ".builders[0].source_image = \"${SOURCE_ID}\" | .builders[0].image_name = \"${BUILD_NAME}\" | .builders[0].availability_zone = \"$AZ\"" packer.json > /tmp/${BUILD_NAME}_packer.json

echo "Building image ${NAME}..."
packer build /tmp/${BUILD_NAME}_packer.json
rm /tmp/${BUILD_NAME}_packer.json

openstack image save --file ${BUILD_NAME}-large.qcow2 ${BUILD_NAME}
openstack image delete ${BUILD_NAME}

echo "Shrinking image..."
echo "==> qemu-img convert -c -o compat=0.10 -O qcow2 $BUILD_NAME $BUILD_NAME.qcow2"
qemu-img convert -c -o compat=0.10 -O qcow2 ${BUILD_NAME}-large.qcow2 ${BUILD_NAME}.qcow2
rm ${BUILD_NAME}-large.qcow2

echo "Creating final image..."
IMAGE_ID=$(openstack image create -f value -c id --disk-format qcow2 --container-format bare --file ${BUILD_NAME}.qcow2 "${NAME}")
echo "Image $IMAGE_ID created!"
rm ${BUILD_NAME}.qcow2

echo "Applying properties..."
for FACT in $(ls $FACT_DIR); do
    [[ $FACT =~ ^nectar_ ]] && continue
    VAL=$(cat $FACT_DIR/$FACT)
    echo "  -> $FACT: '$VAL'..."
    openstack image set --property $FACT=$"$VAL" $IMAGE_ID
done

echo "Applying tags..."
for TAG in $(ls $TAG_DIR); do
    echo "  -> tag: '$TAG'..."
    openstack image set --tag $TAG $IMAGE_ID
done

echo "================================================================================"
echo "  $NAME $BUILD_NUMBER build successful!"
echo "  Image ID: $IMAGE_ID"
echo "================================================================================"
openstack image show --max-width=120 $IMAGE_ID
