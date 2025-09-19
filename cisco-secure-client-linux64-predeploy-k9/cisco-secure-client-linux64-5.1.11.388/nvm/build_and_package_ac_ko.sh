#!/bin/bash

# This script will invoke the script to build NVM kernel module and
# create NVM install tar package, which will contain the built "NVM 
# kernel module". This Install package can be distributed further to
# install NVM without building "NVM Kernel module" on target.
# This script should be called independently.

ANYCONNECTDIR=".."
ACKDFKO="anyconnect_kdf.ko"
VER=`cat ../vpn/update.txt | sed 's/,/./g'`
KDFPKGTARFILE="../cisco-secure-client-linux64-${VER}-predeploy-ac_kdf_ko-k9.tar.gz"
LOGFNAME="cisco-secure-client-linux64-build_and_package_ac_kdf-ko-$(date +%F-%T).log"

# Make sure we are root.
if [ `id | sed -e 's/(.*//'` != "uid=0" ]; then
  echo "You need super user privileges to run this script."
  exit
fi

# Remove older pkg, if exists.
if [ -f ${KDFPKGTARFILE} ]; then
    rm -f ${KDFPKGTARFILE} >> /tmp/${LOGFNAME}
fi

# build kdf in temp
echo "Starting to build Cisco Secure Client Kernel Module..."
echo "./build_ac_ko.sh build `pwd`" >> /tmp/${LOGFNAME}
./build_ac_ko.sh build `pwd` >> /tmp/${LOGFNAME} 2>&1
if [ $? != 0 ]; then
    echo "Failed to build Cisco Secure Client Kernel module. Exiting now."
    exit
fi

# create tar package
touch ${KDFPKGTARFILE}
tar cvzf ${KDFPKGTARFILE} --exclude='build_and_package_ac_ko.sh' --exclude="${KDFPKGTARFILE}" ${ANYCONNECTDIR}/* >> /tmp/${LOGFNAME} 2>&1 || exit

echo "Built Cisco Secure Client kernel module successfully and it is packaged into ${KDFPKGTARFILE}. Please use this package to deploy Cisco Secure Client."

# Move the logfile from tmp to current dir.
mv /tmp/${LOGFNAME} .

#clean up
rm -rf ${ACKDFKO}
