#!/bin/sh

csc_vercmp() 
{
    ver_from="${1:?missing from-version}"
    ver_to="${2:?missing to-version}"

    if [ "$ver_from" = "$ver_to" ]; then
        echo same
    else
        ver_min="$(printf '%s\n' "$ver_from" "$ver_to" | sort -V | head -n1)"
        if [ "$ver_min" = "$ver_from" ]; then
            echo older
        else
            echo newer
        fi
    fi
}

showLicense()
{
    ## The web-based installer used for VPN client installation and upgrades does
    ## not have the license.txt in the current directory, intentionally skipping
    ## the license agreement. Bug CSCtc45589 has been filed for this behavior.
    if [ -f "license.txt" ]; then
        cat ./license.txt
        echo
        echo -n "Do you accept the terms in the license agreement? [y/n] "
        read LICENSEAGREEMENT
        while : 
        do
          case ${LICENSEAGREEMENT} in
               [Yy][Ee][Ss])
                       echo "You have accepted the license agreement."
                       echo "Please wait while ${CLIENTNAME} is being installed..."
                       break
                       ;;
               [Yy])
                       echo "You have accepted the license agreement."
                       echo "Please wait while ${CLIENTNAME} is being installed..."
                       break
                       ;;
               [Nn][Oo])
                       echo "The installation was cancelled because you did not accept the license agreement."
                       exit 1
                       ;;
               [Nn])
                       echo "The installation was cancelled because you did not accept the license agreement."
                       exit 1
                       ;;
               *)    
                       echo "Please enter either \"y\" or \"n\"."
                       read LICENSEAGREEMENT
                       ;;
          esac
        done
    fi
}

createTempDir()
{
  if [ "`basename $0`" != $1 ]; then
    if which mktemp >/dev/null 2>&1; then
      TEMPDIR=`mktemp -d /tmp/nvm.XXXXXX`
      RMTEMP="yes"
    else
      TEMPDIR="/tmp"
      RMTEMP="no"
    fi
  else
    TEMPDIR="."
  fi
}

deleteKDFFilesDuringUpgrade()
{
  # In upgrades, build_ac_ko.sh & kdf src tar file should be deleted from NVM dir,
  # before moving NVM files to temp dir.
  if [ -f ${NVMDIR}/${KDFSRCTARFILE} ]; then
    echo "rm -f ${NVMDIR}/${KDFSRCTARFILE}" >> /tmp/${LOGFNAME}
    rm -f ${NVMDIR}/${KDFSRCTARFILE} >> /tmp/${LOGFNAME} 2>&1
  fi

  if [ -f ${NVMDIR}/build_ac_ko.sh ]; then
    echo "rm -f ${NVMDIR}/build_ac_ko.sh" >> /tmp/${LOGFNAME}
    rm -f ${NVMDIR}/build_ac_ko.sh >> /tmp/${LOGFNAME} 2>&1
  fi
}

copyNVMFilesToTempDuringUpgrade()
{

  if [ -f ${AC_KCONFIGFILE} ] && [ ! -f ${CSC_KCONFIGFILE} ]; then
    echo "Migrating files from ${AC_NVMDIR} directory to ${NVMDIR} directory"
    mkdir -p ${TMPNVMDIR}
    # Except folders all files within the NVM directory will be cached
    find ${AC_NVMDIR}  -maxdepth 1 -type f ! -name lib,bin -exec cp -t ${TMPNVMDIR} {} + >> /tmp/${LOGFNAME} 2>&1
    return
  fi
  # In upgrades, NVM files will be copied to a temp directory and moved back
  if [ -d ${NVMDIR} ]; then
    echo "mv -f ${NVMDIR} ${TMPNVMDIR}" >> /tmp/${LOGFNAME}
    mkdir -p ${TMPNVMDIR}
    # Except folders all files within the NVM directory will be cached
    find ${NVMDIR} -maxdepth 1 -type f ! -name lib,bin -exec cp -t ${TMPNVMDIR} {} + >> /tmp/${LOGFNAME} 2>&1
  fi
}

uninstallPreviousVersion()
{
 if [ -x $1 ]; then
    echo "Removing previous installation..."
    echo "Removing previous installation: $1" >> /tmp/${LOGFNAME}
    if ! $1; then
      echo "Error removing previous installation!  Continuing..."
      echo "Error removing previous installation!  Continuing..." >> /tmp/${LOGFNAME}
    fi
  fi
}

extractAndUnarchive()
{
  if [ "${TEMPDIR}" != "." ]; then
    TARNAME=`date +%N`
    TARFILE=${TEMPDIR}/nvminst${TARNAME}.tgz

    echo "Extracting installation files to ${TARFILE}..."
    echo "Extracting installation files to ${TARFILE}..." >> /tmp/${LOGFNAME}
    # "head --bytes=-1" used to remove '\n' prior to MARKER_END
    head -n ${MARKER_END} $0 | tail -n +${MARKER} | head --bytes=-1 2>> /tmp/${LOGFNAME} > ${TARFILE} || exit 1

    echo "Unarchiving installation files to ${TEMPDIR}..."
    echo "Unarchiving installation files to ${TEMPDIR}..." >> /tmp/${LOGFNAME}
    tar xvzf ${TARFILE} -C ${TEMPDIR} >> /tmp/${LOGFNAME} 2>&1 || exit 1

    rm -f ${TARFILE}

    NEWTEMP="${TEMPDIR}/${TARROOT}"
  else
    NEWTEMP="."
  fi
}

checkVersionFeasibilityWithVPN()
{
  failed=false
  # version of NVM being installed has to be same as installed VPN version
  if [ -f ${VPNMANIFEST} ]; then
      VPNVERSION=$(awk -F"\"" '/file version/ { print $2 }' ${VPNMANIFEST})
      NVMCURRVERSION=5.1.11.388

      if [ "$STANDALONE_FLAG" = true ]; then
        failed=true
      else
        vpn_ver="$(csc_vercmp "$VPNVERSION" "$NVMCURRVERSION")"
        if [ "$vpn_ver" != same ]; then
          failed=true
        fi
      fi
  fi

  if [ "$failed" = true ]; then
      echo "Please use nvm installer from Cisco Secure Client package with version ${VPNVERSION} for the installation"
      echo "Please use nvm installer from Cisco Secure Client package with version ${VPNVERSION} for the installation" >> /tmp/${LOGFNAME}
      echo "Exiting now."
      echo "Exiting now." >> /tmp/${LOGFNAME}
      exit 1
  fi
}

checkVersionFeasibilityWithNVM()
{
  failed=false
  # version of NVM being installed has to be greater than the current NVM version
  if [ "$STANDALONE_FLAG" = true ] && [ -f ${NVMMANIFEST} ]; then
      NVMPREVVERSION=$(awk -F"\"" '/file version/ { print $2 }' ${NVMMANIFEST})
      NVMCURRVERSION=5.1.11.388

      existing_ver="$(csc_vercmp "$NVMPREVVERSION" "$NVMCURRVERSION")"
      if [ "$existing_ver" != older ]; then
        failed=true
      fi
  fi

  if [ "$failed" = true ]; then
    if [ "$existing_ver" = same ]; then
      echo "Version ${NVMCURRVERSION} is already installed!"
      echo "Version ${NVMCURRVERSION} is already installed!" >> /tmp/${LOGFNAME}
    else
      echo "A higher version ${NVMPREVVERSION} of NVM is already installed!"
      echo "A higher version ${NVMPREVVERSION} of NVM is already installed!" >> /tmp/${LOGFNAME}
    fi
    echo "Exiting now."
    echo "Exiting now." >> /tmp/${LOGFNAME}
    exit 1
  fi
}

checkBPFAndBTFSupport()
{
  # Check for eBPF support
  if [ -d /sys/fs/bpf ]; then
    echo "eBPF support detected via /sys/fs/bpf."
    echo "eBPF support detected via /sys/fs/bpf." >> /tmp/${LOGFNAME}
  else
    echo "eBPF support not detected."
    echo "eBPF support not detected." >> /tmp/${LOGFNAME}
    return 1
  fi

  # Check for BTF support using /sys/kernel/btf/vmlinux
  if [ -f /sys/kernel/btf/vmlinux ]; then
    echo "BTF support detected via /sys/kernel/btf/vmlinux."
    echo "BTF support detected via /sys/kernel/btf/vmlinux." >> /tmp/${LOGFNAME}
  else
    echo "BTF support not detected (/sys/kernel/btf/vmlinux not found)."
    echo "BTF support not detected (/sys/kernel/btf/vmlinux not found)." >> /tmp/${LOGFNAME}
    return 1
  fi

  return 0
}

buildKDF()
{
  # build KDF first, if .ko doesn't exist.
  cd ${NEWTEMP}
  ACKDFKO="anyconnect_kdf.ko"
  if [ ! -f "${ACKDFKO}" ]; then
      echo "Starting to build Cisco Secure Client Kernel Module..."
      echo "./build_ac_ko.sh build `pwd`" >> /tmp/${LOGFNAME}
      ./build_ac_ko.sh build `pwd` >> /tmp/${LOGFNAME} 2>&1
      if [ $? != 0 ]; then
          echo "Failed to build Cisco Secure Client Kernel module."
          echo "Continuing installation without the kernel module."
          return 1
      else
          echo "Cisco Secure Client Kernel module built successfully."
      fi
  fi
  return 0
}

installKDF()
{
  mkdir -p ${KERNELDRIVERDIR}
  echo "Installing "${NEWTEMP}/${ACKDFKO} >> /tmp/${LOGFNAME}
  if ! ${INSTALL} -o root -m 755 ${NEWTEMP}/${ACKDFKO} ${KERNELDRIVERDIR}; then
      echo "Failed to install the kernel module. Continuing installation without it." >> /tmp/${LOGFNAME}
      echo "Failed to install the kernel module. Continuing installation without it."
      return 1
  fi

  echo "Updating kernel module dependencies"
  /sbin/depmod -a

# Check the kernel driver compatiblity
  echo "Checking if kernel driver is compatible."
  echo "Checking if kernel driver is compatible." >> /tmp/${LOGFNAME}
  echo "/sbin/modprobe -q anyconnect_kdf" >> /tmp/${LOGFNAME}
  if ! /sbin/modprobe -q anyconnect_kdf; then
      echo "Error. Unable to load the Kernel driver." >> /tmp/${LOGFNAME}
      echo "Error. Unable to load the Kernel driver."
      echo "Continuing installation without the kernel module." >> /tmp/${LOGFNAME}
      echo "Continuing installation without the kernel module."
      return 1
  fi
  return 0
}

createDir()
{
  DIR=$1
  echo "Installing "${DIR} >> /tmp/${LOGFNAME}
  ${INSTALL} -d ${DIR} || exit 1
}

copyKDFFilesToNVMDir()
{
  # Copy KDF source & build_ac_kdf_ko.sh to NVM dir.
  if [ -d ${NVMDIR} ]; then
      echo "cp -af ${NEWTEMP}/${KDFSRCTARFILE} ${NVMDIR}" >> /tmp/${LOGFNAME}
      cp -af ${NEWTEMP}/${KDFSRCTARFILE} ${NVMDIR} >> /tmp/${LOGFNAME}

      echo "cp -af ${NEWTEMP}/build_ac_kdf_ko.sh ${NVMDIR}" >> /tmp/${LOGFNAME}
      cp -af ${NEWTEMP}/build_ac_ko.sh ${NVMDIR} >> /tmp/${LOGFNAME}
  fi
}

copyFiles()
{
  echo "Installing "${NEWTEMP}/$1 >> /tmp/${LOGFNAME}
  ${INSTALL} -o root -m 755 ${NEWTEMP}/$1 $2 || exit 1
}

updateVPNManifestFile()
{
  # Generate/update the VPNManifest.dat file
  ${BINDIR}/manifesttool_nvm -i ${INSTPREFIX} ${INSTPREFIX}/ACManifestNVM.xml
}

removeTMPDIR()
{
  if [ "${RMTEMP}" = "yes" ]; then
    echo rm -rf ${TEMPDIR} >> /tmp/${LOGFNAME}
    rm -rf ${TEMPDIR}
  fi
}

restoreNVMDirDuringUpgrade()
{
  # In upgrades, we restore the NVM directory from the temp dir
  if [ -d ${TMPNVMDIR} ]; then
    echo "Moving NVM config files back to NVM directory" >> /tmp/${LOGFNAME}
    mkdir -p ${NVMDIR}
    tar cf - -C ${TMPNVMDIR} . | (cd ${NVMDIR}; tar xf -) >> /tmp/${LOGFNAME} 2>&1
    rm -rf ${TMPNVMDIR}
  fi  
}

BASH_BASE_SIZE=0x00000000
CISCO_AC_TIMESTAMP=0x0000000000000000
CISCO_AC_OBJNAME=1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456
# BASH_BASE_SIZE=0x00000000 is required for signing
# CISCO_AC_TIMESTAMP is also required for signing
# comment is after BASH_BASE_SIZE or else sign tool will find the comment

TARROOT="nvm"
INSTPREFIX=/opt/cisco/secureclient
NVMDIR=${INSTPREFIX}/NVM
BINDIR=${NVMDIR}/bin
LIBDIR=${NVMDIR}/lib
TMPNVMDIR=${INSTPREFIX}/NVM.tmp
KERNELDRIVERDIR=/lib/modules/$(uname -r)/extra/cisco/
INSTALL=install
MARKER=$((`grep -an "[B]EGIN\ ARCHIVE" $0 | cut -d ":" -f 1` + 1))
MARKER_END=$((`grep -an "[E]ND\ ARCHIVE" $0 | cut -d ":" -f 1` - 1))
LOGFNAME=`date "+cisco-secure-client-linux64-5.1.11.388-nvm-install-%H%M%S%d%m%Y.log"`
CLIENTNAME="Cisco Secure Client - Network Visibility Module"
VPNMANIFEST="${INSTPREFIX}/ACManifestVPN.xml"
NVMMANIFEST="${INSTPREFIX}/ACManifestNVM.xml"
KDFSRCTARFILE="ac_kdf_src.tar.gz"
LEGACY_UNINST="${INSTPREFIX}/bin/nvm_uninstall.sh"
UNINST=${BINDIR}/nvm_uninstall.sh
TEMPDIR="."
RMTEMP=""
NEWTEMP="."
VPNVERSION=""
NVMCURRVERSION=""
NVMPREVVERSION=""
ACKDFKO=""
AC_INSTPREFIX=/opt/cisco/anyconnect
AC_NVMDIR="${AC_INSTPREFIX}/NVM"
AC_KCONFIGFILE="${AC_NVMDIR}/KConfig.dat"
CSC_KCONFIGFILE="${NVMDIR}/KConfig.dat"
AC_UNINST="${AC_NVMDIR}/bin/nvm_uninstall.sh"
AC_NVMMANIFEST="${AC_INSTPREFIX}/ACManifestNVM.xml"

UNINSTALLER_SCRIPTS="${LEGACY_UNINST} \
                     ${AC_UNINST} \
                     ${UNINST}"

echo "Installing ${CLIENTNAME}..."
echo "Installing ${CLIENTNAME}..." > /tmp/${LOGFNAME}
echo `whoami` "invoked $0 from " `pwd` " at " `date` >> /tmp/${LOGFNAME}

#Set a trap so that the log file is moved to ${INSTPREFIX}/. in any exit path
trap 'mv /tmp/${LOGFNAME} ${INSTPREFIX}/.' EXIT

# Make sure we are root
if [ `id | sed -e 's/(.*//'` != "uid=0" ]; then
  echo "Sorry, you need super user privileges to run this script."
  exit 1
fi

#!/bin/sh

PLUGINDIR=${INSTPREFIX}/bin/plugins
STANDALONE_FLAG=false

# NVM requires VPN to be installed. We check the presence of the vpn manifest file to check if it is installed.
if [ ! -f ${VPNMANIFEST} ]; then
    echo "VPN should be installed before NVM installation. Install VPN to proceed."
    echo "Exiting now."
    exit 1
fi

showLicense

# version of NVM being installed has to be greater than the current NVM version
checkVersionFeasibilityWithNVM

# version of NVM being installed has to be same as installed VPN version
checkVersionFeasibilityWithVPN

createTempDir "nvm_install.sh"

# In upgrades, build_ac_ko.sh & kdf src tar file should be deleted from NVM dir, 
# before moving NVM files to temp dir.
deleteKDFFilesDuringUpgrade

# In upgrades, NVM files will be copied to a temp directory and moved back
copyNVMFilesToTempDuringUpgrade

for UNINSTALLER_SCRIPT in ${UNINSTALLER_SCRIPTS};do
  #Check for and uninstall any previous version.
  uninstallPreviousVersion ${UNINSTALLER_SCRIPT}
done

extractAndUnarchive

checkBPFAndBTFSupport
BPF_BTF_SUPPORTED=$?

# build KDF first, if .ko doesn't exist.
buildKDF
buildKDFStatus=$?

if [ $BPF_BTF_SUPPORTED -ne 0 ] && [ $buildKDFStatus -ne 0 ]; then
  echo "Error: Failed to build KDF. Exiting installation." >> /tmp/${LOGFNAME}
  exit 1
fi

# Return to previous directory.
cd - >/dev/null

# Make sure destination directories exist
# Since vpn installer creates these directories need to revisit
DIRS="${BINDIR} \
      ${LIBDIR} \
      ${NVMDIR} \
      ${PLUGINDIR}"

for DIR in ${DIRS}; do
  createDir ${DIR}
done

# Copy KDF source & build_ac_kdf_ko.sh to NVM dir.
copyKDFFilesToNVMDir

BINFILES="nvm_uninstall.sh \
          acnvmagent \
          manifesttool_nvm \
          osqueryi"

LIBFILES="libacruntime.so \
          libacciscossl.so \
          libacciscocrypto.so \
          libaccurl.so.4.8.0 \
          libsock_fltr_api.so \
          libboost_date_time.so \
          libboost_atomic.so \
          libboost_filesystem.so \
          libboost_system.so \
          libboost_thread.so \
          libboost_chrono.so"

for BINFILE in ${BINFILES}; do
    copyFiles ${BINFILE} ${BINDIR}
done

for LIBFILE in ${LIBFILES}; do
    copyFiles ${LIBFILE} ${LIBDIR}
done

# create symlink for libcurl
echo "ln -s libaccurl.so.4.8.0 libaccurl.so.4" >> /tmp/${LOGFNAME}
ln -s libaccurl.so.4.8.0 ${LIBDIR}/libaccurl.so.4 || exit 1

installKDF
installKDFStatus=$?

if [ $BPF_BTF_SUPPORTED -ne 0 ] && [ $installKDFStatus -ne 0 ]; then
  echo "Error: Failed to install KDF. Exiting installation." >> /tmp/${LOGFNAME}
  exit 1
fi

echo "Installing "${NEWTEMP}/plugins/libacnvmctrl.so >> /tmp/${LOGFNAME}
${INSTALL} -o root -m 755 ${NEWTEMP}/plugins/libacnvmctrl.so ${NVMDIR} || exit 1

echo "Installing "${NEWTEMP}/ACManifestNVM.xml >> /tmp/${LOGFNAME}
${INSTALL} -o root -m 444 ${NEWTEMP}/ACManifestNVM.xml ${INSTPREFIX} || exit 1

# Generate/update the VPNManifest.dat file
updateVPNManifestFile

removeTMPDIR

# In upgrades, we restore the NVM directory from the temp dir
restoreNVMDirDuringUpgrade

# Move the NVM plugin to the plugins director
echo "Moving "${NVMDIR}/libacnvmctrl.so >> /tmp/${LOGFNAME}
mv -f ${NVMDIR}/libacnvmctrl.so ${PLUGINDIR} || exit 1

echo "${CLIENTNAME} is installed successfully."
echo "${CLIENTNAME} is installed successfully." >> /tmp/${LOGFNAME}

exit 0

--BEGIN ARCHIVE--
