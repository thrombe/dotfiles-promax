#!/bin/bash

mkdir s3_temp
cd s3_temp

sudo acpidump -b

# decompile
iasl -e *.dat -d dsdt.dat

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

cp 

mv ..


