#!/bin/sh
#

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

checkInstalledHSVersion()
{
  failed=false
  # version of HS being installed has to be greater than the current HS version
  if [ -f ${HSMANIFEST} ]; then
      HSPREVVERSION=$(awk -F"\"" '/file version/ { print $2 }' ${HSMANIFEST})
      HSCURRVERSION=5.1.11.388

      existing_ver="$(csc_vercmp "$HSPREVVERSION" "$HSCURRVERSION")"
      if [ "$existing_ver" != older ]; then
        failed=true
      fi
  fi

  if [ "$failed" = true ]; then
    if [ "$existing_ver" = same ]; then
      echo "Version ${HSCURRVERSION} is already installed!"
      echo "Version ${HSCURRVERSION} is already installed!" >> /tmp/${LOGFNAME}
    else
      echo "A higher version ${HSPREVVERSION} of Secure Firewall Posture Module is already installed!"
      echo "A higher version ${HSPREVVERSION} of Secure Firewall Posture Module is already installed!" >> /tmp/${LOGFNAME}
    fi
    exitInstallation 1
  fi
}

exitInstallation()
{
  echo "Exiting now."
  echo "Exiting now." >> /tmp/${LOGFNAME}

  if [ ! -f "${LOGDIR}" ] ; then
    mkdir -p ${LOGDIR}
  fi
  # move the logfile out of the tmp directory
  mv /tmp/${LOGFNAME} ${LOGDIR}
  exit $1
}

#
# Set up to do reads with possible shell escape and default assignment
#
getvalue() {
    ans='!'

    echo 
    echo -n "$1 [$2] "

        while expr "X$ans" : "X!" >/dev/null; do
                read ans
                case "$ans" in
                        !)
                                sh
                                echo " "
                                echo $n "$rp $c"
                                ;;
                        !*)
                                set `expr "X$ans" : "X!\(.*\)$"`
                                sh -c "$*"
                                echo " "
                                echo $n "$rp $c"
                                ;;
                        esac
        done

        if [ -z "$ans" ]; then
        ans="$2"
    fi
}

CSC_INSTPREFIX="/opt/cisco/secureclient"
POSTUREMANIFEST="ACManifestPOS.xml"
HSMANIFEST="${CSC_INSTPREFIX}/${POSTUREMANIFEST}"
INSTPREFIX="${CSC_INSTPREFIX}/securefirewallposture"
SYSTEMD_UNIT="ciscod.service"
SYSTEMD_UNIT_DIR="/etc/systemd/system"
BINDIR=${INSTPREFIX}/bin
LIBDIR=${INSTPREFIX}/lib
LOGDIR=${INSTPREFIX}/log
PLUGINDIR="${CSC_INSTPREFIX}/bin/plugins"
SYSVSTART="S85"
SYSVSTARTNUM="85"
SYSVSTOP="K25"
SYSVSTOPNUM="25"
SYSVLEVELS="2 3 4 5"
CURRENTDIR=`dirname $0 2> /dev/null`
VPNMANIFEST="${CSC_INSTPREFIX}/ACManifestVPN.xml"

LOGFNAME=`/bin/date "+posture-5.1.11.388-install-%H%M%S%d%m%Y.log"` ||
  LOGFNAME=`/usr/bin/date "+posture-5.1.11.388-install-%H%M%S%d%m%Y.log"` ||
  LOGFNAME=`date "+posture-5.1.11.388-install-%H%M%S%d%m%Y.log"` ||
  LOGFNAME=posture-5.1.11.388-install.log

DIR=`dirname $0 2> /dev/null` || 
  DIR=`/usr/bin/dirname $0 2> /dev/null` || 
  DIR=`/bin/dirname $0 2> /dev/null` || 
  DIR=.

ID=`id -u  2> /dev/null` || ID=`/usr/bin/id -u  2> /dev/null` ||
  ID=`/usr/bin/id -u  2> /dev/null`

if [ -x "/usr/bin/install" ]; then
    INSTALL="/usr/bin/install"
elif [ -x "/bin/install" ]; then
    INSTALL="/bin/install"
elif [ -x "/usr/local/bin/install" ]; then
    INSTALL="/usr/local/bin/install"
else
    INSTALL="install"
fi
${INSTALL} --help 2> /dev/null > /dev/null
if [ $? != 0 ]; then
    INSTALL=""
fi

ARG_NO_LICENSE=0
ARG_NO_PROMPT=0
PREDEPLOY_LAUNCHER=1

for i in $*
do
    if [ "x${i}" = "x--no-license" ]; then
        ARG_NO_LICENSE=1
        PREDEPLOY_LAUNCHER=0
    fi

    if [ "x${i}" = "x--no-prompt" ]; then
        ARG_NO_PROMPT=1
    fi
done

echo "Installing Cisco Secure Client - Secure Firewall Posture..."
echo "Installing Cisco Secure Client - Secure Firewall Posture v5.1.11.388..." > /tmp/${LOGFNAME}
echo `whoami` "invoked $0 from " `pwd` " at " `date` >> /tmp/${LOGFNAME}
echo ""

# Make sure we are root
if [ "x${ID}" != "x0" ]; then
  echo "Sorry, you need super user privileges to run this script."
  exitInstallation 1
fi

# Posture requires VPN to be installed. We check the presence of the vpn manifest file to check if it is installed.
if [ ! -f ${VPNMANIFEST} ]; then
    echo "AnyConnect VPN should be installed before Posture installation. Install Cisco Secure Client - AnyConnect VPN to proceed."
    echo "AnyConnect VPN should be installed before Posture installation. Install Cisco Secure Client - AnyConnect VPN to proceed." >> /tmp/${LOGFNAME}
    exitInstallation 1
fi

postureVersionMatchesVPN=false
# version of posture being installed has to be same as installed VPN version
if [ -f "${CURRENTDIR}/${POSTUREMANIFEST}" ] && [ -f ${VPNMANIFEST} ]; then
    VPNVERSION=$(awk -F"\"" '/file version/ { print $2 }' ${VPNMANIFEST})
    POSTURECURRVERSION=$(awk -F"\"" '/file version/ { print $2 }' ${CURRENTDIR}/${POSTUREMANIFEST})

    vpn_ver="$(csc_vercmp "$VPNVERSION" "$POSTURECURRVERSION")"
    if [ "$vpn_ver" = same ]; then
     postureVersionMatchesVPN=true
    fi
fi

if [ "$postureVersionMatchesVPN" = false ]; then
    echo "Please use posture installer from Cisco Secure Client package with version ${VPNVERSION} for the installation"
    echo "Please use posture installer from Cisco Secure Client package with version ${VPNVERSION} for the installation" >> /tmp/${LOGFNAME}
    exitInstallation 1
fi

if [ "x${ARG_NO_LICENSE}" = "x1" ]; then

    echo "Skipping license text ..."

else

    if [ -f "${DIR}/license.txt" ]; then
        more ${DIR}/license.txt
    else
        echo "License file not found. Aborting installation."
        exitInstallation 1
    fi

    getvalue "Do you accept the Client Software License Agreement of Cisco Systems[y/n]?" "n"
    response=$ans

    while :
    do
        case "$response" in
            [Yy][Ee][Ss] | [Yy])
                echo "You have accepted the license agreement."
                echo "Please wait while Cisco Secure Client - Secure Firewall Posture is being installed..."
                break
                ;;
            [Nn][Oo] | [Nn])
                echo "The installation was cancelled because you did not accept the license agreement."
                exitInstallation 1
                ;;
            *)
                echo ""
                echo -n "Please enter either \"y\" or \"n\"."
                getvalue "Do you accept the Client Software License Agreement of Cisco Systems[y/n]?" "n"
                response=$ans
                ;;
        esac
    done
fi
    
echo -n "Creating directories... "

if [ "x${INSTALL}" = "x" ]; then
    echo "failed."
    echo "Unable to find install command."
    exitInstallation 1
fi

checkInstalledHSVersion

HOSTSCANDIR="/opt/cisco/hostscan"
if [ -x ${HOSTSCANDIR} ]; then
  ${HOSTSCANDIR}/bin/posture_uninstall.sh
  if [ "$?" -ne "0" ]; then
    echo "Error removing previous version of HostScan!  Continuing..." >> /tmp/${LOGFNAME}
  fi
fi

if [ -d "${HOSTSCANDIR}" ]; then
  echo "Removing HostScan Directory ${HOSTSCANDIR}..." >> /tmp/${LOGFNAME}
  rm -rf ${HOSTSCANDIR}
fi

SFPUNINST="${BINDIR}/posture_uninstall.sh"
if [ -x ${SFPUNINST} ]; then
  ${SFPUNINST}
  if [ "$?" -ne "0" ]; then
    echo "Error removing previous version of SecureFWPosture!  Continuing..." >> /tmp/${LOGFNAME}
  fi
fi


# Make sure destination directories exist
echo "Installing "${BINDIR} >> /tmp/${LOGFNAME}
${INSTALL} -d ${BINDIR} || ( echo "failed." && exitInstallation 1 )

echo "Installing "${LIBDIR} >> /tmp/${LOGFNAME}
${INSTALL} -d ${LIBDIR} || ( echo "failed." && exitInstallation 1 )

echo "Installing "${LOGDIR} >> /tmp/${LOGFNAME}
${INSTALL} -d ${LOGDIR} || ( echo "failed." && exitInstallation 1 )

echo "done."

echo -n "Copying files... "

# Copy files to their home
echo "Installing "${DIR}/cstub >> /tmp/${LOGFNAME}
${INSTALL} -o root -m 755 ${DIR}/cstub ${BINDIR} || 
    ( echo "failed." && exitInstallation 1 )

echo "Installing "${DIR}/ciscod >> /tmp/${LOGFNAME}
${INSTALL} -o root -m 755 ${DIR}/ciscod ${BINDIR} ||
    ( echo "failed." && exitInstallation 1 )

echo "Installing "${DIR}/cscan >> /tmp/${LOGFNAME}
${INSTALL} -o root -m 755 ${DIR}/cscan ${BINDIR} ||
    ( echo "failed." && exitInstallation 1 )

#osqueryi is only included in predeploy packages.
if [ "x${PREDEPLOY_LAUNCHER}" = "x1" ]; then
    echo "Installing "${DIR}/osqueryi >> /tmp/${LOGFNAME}
    ${INSTALL} -o root -m 755 ${DIR}/osqueryi ${BINDIR} ||
        ( echo "failed." && exitInstallation 1 )
fi

echo "Installing "${DIR}/manifesttool_posture >> /tmp/${LOGFNAME}
${INSTALL} -o root -m 755 ${DIR}/manifesttool_posture ${BINDIR} || 
    ( echo "failed." && exitInstallation 1 )

echo "Installing "${DIR}/libhostscan.so >> /tmp/${LOGFNAME}
${INSTALL} -o root -m 755 ${DIR}/libhostscan.so ${LIBDIR} ||
    ( echo "failed." && exitInstallation 1 )

echo "Installing "${DIR}/libcsd.so >> /tmp/${LOGFNAME}
${INSTALL} -o root -m 755 ${DIR}/libcsd.so ${LIBDIR} || 
    ( echo "failed." && exitInstallation 1 )

echo "Installing "${DIR}/libinspector.so >> /tmp/${LOGFNAME}
${INSTALL} -o root -m 755 ${DIR}/libinspector.so ${LIBDIR} || 
    ( echo "failed." && exitInstallation 1 )

echo "Installing "${DIR}/wadiagnose >> /tmp/${LOGFNAME}
${INSTALL} -o root -m 755 ${DIR}/wadiagnose ${LIBDIR} || 
    ( echo "failed." && exitInstallation 1 )

echo "Installing "${DIR}/libwaapi.so >> /tmp/${LOGFNAME}
${INSTALL} -o root -m 755 ${DIR}/libwaapi.so ${LIBDIR} ||
    ( echo "failed." && exitInstallation 1 )

echo "Installing "${DIR}/libwacollector.so >> /tmp/${LOGFNAME}
${INSTALL} -o root -m 755 ${DIR}/libwacollector.so ${LIBDIR} ||
    ( echo "failed." && exitInstallation 1 )

echo "Installing "${DIR}/libwaheap.so.4 >> /tmp/${LOGFNAME}
${INSTALL} -o root -m 755 ${DIR}/libwaheap.so.4 ${LIBDIR} ||
    ( echo "failed." && exitInstallation 1 )

echo "Installing "${DIR}/libwalocal.so >> /tmp/${LOGFNAME}
${INSTALL} -o root -m 755 ${DIR}/libwalocal.so ${LIBDIR} ||
    ( echo "failed." && exitInstallation 1 )

echo "Installing "${DIR}/libwalocal.so.4 >> /tmp/${LOGFNAME}
${INSTALL} -o root -m 755 ${DIR}/libwalocal.so.4 ${LIBDIR} ||
    ( echo "failed." && exitInstallation 1 )

echo "Installing "${DIR}/libwaresource.so >> /tmp/${LOGFNAME}
${INSTALL} -o root -m 755 ${DIR}/libwaresource.so ${LIBDIR} ||
    ( echo "failed." && exitInstallation 1 )

echo "Installing "${DIR}/libwautils.so >> /tmp/${LOGFNAME}
${INSTALL} -o root -m 755 ${DIR}/libwautils.so ${LIBDIR} ||
    ( echo "failed." && exitInstallation 1 )

echo "Installing "${DIR}/libwautils.so.4 >> /tmp/${LOGFNAME}
${INSTALL} -o root -m 755 ${DIR}/libwautils.so.4 ${LIBDIR} ||
    ( echo "failed." && exitInstallation 1 )

echo "Installing "${DIR}/license.cfg >> /tmp/${LOGFNAME}
${INSTALL} -o root -m 644 ${DIR}/license.cfg ${LIBDIR} ||
    ( echo "failed." && exitInstallation 1 )

#libhsappsensor.so is only included in predeploy packages.
if [ "x${PREDEPLOY_LAUNCHER}" = "x1" ]; then
    echo "Installing "${DIR}/libhsappsensor.so >> /tmp/${LOGFNAME}
    ${INSTALL} -o root -m 755 ${DIR}/libhsappsensor.so ${LIBDIR} || 
        ( echo "failed." && exitInstallation 1 )
fi

echo "Installing "${DIR}/csc_sfpuiplugin.so >> /tmp/${LOGFNAME}
${INSTALL} -o root -m 755 ${DIR}/csc_sfpuiplugin.so ${BINDIR} ||
    ( echo "failed." && exitInstallation 1 )

echo "Installing "${DIR}/posture_uninstall.sh >> /tmp/${LOGFNAME}
${INSTALL} -o root -m 755 ${DIR}/posture_uninstall.sh ${BINDIR} || 
    ( echo "failed." && exitInstallation 1 )
ln -f -s ${BINDIR}/posture_uninstall.sh ${BINDIR}/csd_uninstall.sh
chmod 755 ${BINDIR}/csd_uninstall.sh
echo "done."

# hostscan downgrade support related directory.
HOSTSCAN_DOWNGRADE_SYMLINK="/opt/cisco/hostscan"
HOSTSCAN_DOWNGRADE_DIR="/opt/cisco/anyconnect/securefirewallposture/ac_hostscan"

echo "Making provision for AnyConnect Hostscan..."
echo "Making provision for AnyConnect Hostscan..." >> /tmp/${LOGFNAME}

echo "Installing AnyConnect Hostscan directory ${HOSTSCAN_DOWNGRADE_DIR}" >> /tmp/${LOGFNAME}
${INSTALL} -d ${HOSTSCAN_DOWNGRADE_DIR} || ( echo "failed." && exitInstallation 1 )
# ${INSTALL} -o root -m 755 ${HOSTSCAN_DOWNGRADE_DIR} || ( echo "failed." && exitInstallation 1 )
echo "Installing AnyConnect Hostscan bin directory ${HOSTSCAN_DOWNGRADE_DIR}/bin" >> /tmp/${LOGFNAME}
${INSTALL} -d ${HOSTSCAN_DOWNGRADE_DIR}/bin || ( echo "failed." && exitInstallation 1 )
echo "Installing AnyConnect Hostscan lib directory ${HOSTSCAN_DOWNGRADE_DIR}/lib" >> /tmp/${LOGFNAME}
${INSTALL} -d ${HOSTSCAN_DOWNGRADE_DIR}/lib || ( echo "failed." && exitInstallation 1 )
echo "Installing AnyConnect Hostscan log directory ${HOSTSCAN_DOWNGRADE_DIR}/log" >> /tmp/${LOGFNAME}
${INSTALL} -d ${HOSTSCAN_DOWNGRADE_DIR}/log || ( echo "failed." && exitInstallation 1 )

if [ ! -e ${HOSTSCAN_DOWNGRADE_SYMLINK} ]; then
  echo "Creating AnyConnect Hostscan symbolic link" >> /tmp/${LOGFNAME}
  echo "ln -f -s ${HOSTSCAN_DOWNGRADE_DIR} ${HOSTSCAN_DOWNGRADE_SYMLINK}"  >> /tmp/${LOGFNAME}
  ln -f -s ${HOSTSCAN_DOWNGRADE_DIR} ${HOSTSCAN_DOWNGRADE_SYMLINK} || ( echo "failed." && exitInstallation 1 )
fi

echo "Done Making provision for AnyConnect Hostscan."
echo "Done Making provision for AnyConnect Hostscan." >> /tmp/${LOGFNAME}

# systemctl bin location
if [ -x "/bin/systemctl" ]; then
  SYSTEMCTL="/bin/systemctl"
fi

TESTINIT=`ls -l /proc/1/exe`
if [ -z "${TESTINIT##*"systemd"*}" ]; then
    echo -n "Stopping the Cisco Secure Client - Secure Firewall Posture agent... "
    ${SYSTEMCTL} stop ${SYSTEMD_UNIT} >> /tmp/${LOGFNAME} 2>&1
    ${SYSTEMCTL} disable ${SYSTEMD_UNIT} >> /tmp/${LOGFNAME} 2>&1
    echo "done."

    # Install the new systemd service file
    echo -n "Installing systemd config... " 
    echo ${INSTALL} -o root -m 644 -T ${DIR}/${SYSTEMD_UNIT} ${SYSTEMD_UNIT_DIR}/${SYSTEMD_UNIT} >> /tmp/${LOGFNAME}
    ${INSTALL} -o root -m 644 -T ${DIR}/${SYSTEMD_UNIT} ${SYSTEMD_UNIT_DIR}/${SYSTEMD_UNIT} || ( echo "failed." && exitInstallation 1 )
    echo "done."
    
    logger "Starting the Cisco Secure Client - Secure Firewall Posture service..."
    echo -n "Starting the Cisco Secure Client - Secure Firewall Posture service... "
    echo "Starting the Cisco Secure Client - Secure Firewall Posture service..." >> /tmp/${LOGFNAME}

    echo ${SYSTEMCTL} daemon-reload >> /tmp/${LOGFNAME}
    ${SYSTEMCTL} daemon-reload >> /tmp/${LOGFNAME} || ( echo "failed." && exitInstallation 1 )
    echo ${SYSTEMCTL} enable ${SYSTEMD_UNIT} >> /tmp/${LOGFNAME}
    ${SYSTEMCTL} enable ${SYSTEMD_UNIT} >> /tmp/${LOGFNAME} 2>&1 || ( echo "failed." && exitInstallation 1 )
    echo ${SYSTEMCTL} start ${SYSTEMD_UNIT} >> /tmp/${LOGFNAME} 
    ${SYSTEMCTL} start ${SYSTEMD_UNIT} >> /tmp/${LOGFNAME} || ( echo "failed." && exitInstallation 1 )
    echo "done."
else
    echo "Error: systemd required." >> /tmp/${LOGFNAME} || exitInstallation 1
fi

# update manifest
echo "Updating AC manifest." >> /tmp/${LOGFNAME}

${INSTALL} -o root -m 755 ${DIR}/${POSTUREMANIFEST} ${CSC_INSTPREFIX} >> /tmp/${LOGFNAME}
${BINDIR}/manifesttool_posture -i ${CSC_INSTPREFIX} ${CSC_INSTPREFIX}/${POSTUREMANIFEST} >> /tmp/${LOGFNAME}

# Move the Posture plugin to the plugins directory
echo "Moving "${BINDIR}/csc_sfpuiplugin.so >> /tmp/${LOGFNAME}
mv -f ${BINDIR}/csc_sfpuiplugin.so ${PLUGINDIR} || 
    ( echo "failed." && exitInstallation 1 )

echo "Done!"
echo "Done!" >> /tmp/${LOGFNAME}

exitInstallation 0
