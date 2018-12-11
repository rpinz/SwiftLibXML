#!/bin/sh
#
# Remove Packages directory and generated files
#
./clean.sh
exec rm -rf Package.resolved Package.pins SwiftLibXML.xcodeproj
