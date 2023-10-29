#!/bin/env bash

set -e

if command -v mokutil; then
  if [[ ! "$(mokutil --sb-state)" =~ "SecureBoot disabled" ]]; then
    echo "SecureBoot is enabled, please disable and try again"
    exit 1
  fi
fi

# TMP_DIR=$(mktemp -d -t "modify-dsdt-$(date +%Y-%m-%d-%H-%M-%S)-XXXXXXXXXX")
# CURRENT_DIR=$(pwd)

# echo "$TMP_DIR"
# cd "$TMP_DIR"
mkdir s3_temp
cd s3_temp

echo "Dumping data from DSDT tables - sudo is required"
sudo cat /sys/firmware/acpi/tables/DSDT > dsdt.dat
echo "Data succesfully dumped"

echo "Disassemble tables"
iasl -d dsdt.dat
echo "Disassemble completed"

echo "Making modification to tables"
sed -i 's/Name (SS3, Zero)/Name (SS3, One)/g' dsdt.dsl
# This line also required modifying in case of my laptop
sed -i 's/Name (XS3, Package (0x04)/Name (_S3, Package (0x04)/g' dsdt.dsl
echo "Tables are modified"

echo "Increment version"
VERSION_REGEX='(.*DefinitionBlock \(.*,.*,.*,.*,.*, *0x)(.*)(\).*)'
CURRENT_VERSION=$(pcregrep -o2 "${VERSION_REGEX}" dsdt.dsl)
INCREMENTED_VERSION=$(echo "obase=ibase=16;$CURRENT_VERSION+1" | bc)
sed -i -E "s/${VERSION_REGEX}/\1${INCREMENTED_VERSION}\3/g" dsdt.dsl
echo "Version incremented"

echo "Creating AML table"
iasl -tc dsdt.dsl
echo "Created AML table"

echo "Packaging to CPIO archive"
mkdir -p "kernel/firmware/acpi"
cp dsdt.aml "kernel/firmware/acpi"
find kernel | cpio -H newc --create > "./acpi_override.cpio"
echo "Successfully packaged"

cp acpi_override.cpio ../.

cd ..

# echo "copying CPIO archive to /boot/"
# sudo cp "${TMP_DIR}/acpi_override" /boot/acpi_override

# rm -rf "${TMP_DIR}"
