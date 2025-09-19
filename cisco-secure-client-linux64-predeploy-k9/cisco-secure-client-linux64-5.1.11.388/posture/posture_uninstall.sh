#!/bin/sh

CSC_INSTPREFIX="/opt/cisco/secureclient"
INSTPREFIX="${CSC_INSTPREFIX}/securefirewallposture"
BINDIR="${INSTPREFIX}/bin"
LIBDIR="${INSTPREFIX}/lib"
PLUGINDIR="${CSC_INSTPREFIX}/bin/plugins"
SYSTEMD_UNIT="ciscod.service"
SYSTEMD_UNIT_DIR="/etc/systemd/system"
SYSVSTART="S85"
SYSVSTOP="K25"
SYSVLEVELS="2 3 4 5"
LOGDIR="/var/log/secureclient"
LOG="${LOGDIR}/csc_secure_firewall_posture_uninstall.log"
PLUGINFILES="csc_sfpuiplugin.so"

# Create log directory if not exist
if [ ! -d ${LOGDIR} ]; then
  mkdir -p ${LOGDIR} >/dev/null 2>&1
fi

DIR=`dirname $0 2> /dev/null` || 
  DIR=`/usr/bin/dirname $0 2> /dev/null` || 
  DIR=`/bin/dirname $0 2> /dev/null` || 
  DIR=.

ID=`id -u  2> /dev/null` || ID=`/usr/bin/id -u  2> /dev/null` ||
  ID=`/usr/bin/id -u  2> /dev/null`

# systemctl bin location
if [ -x "/bin/systemctl" ]; then
  SYSTEMCTL="/bin/systemctl"
fi

echo "Uninstalling Cisco Secure Client - Secure Firewall Posture..."
echo "Uninstalling Cisco Secure Client - Secure Firewall Posture..." > "${LOG}"
echo `whoami` "invoked $0 from " `pwd` " at " `date` >> "${LOG}"

# Check for root privileges
if [ "x${ID}" != "x0" ]; then
  echo "Sorry, you need super user privileges to run this script."
  echo "Sorry, you need super user privileges to run this script." >> "${LOG}"
  exit 1
fi

TESTINIT=`ls -l /proc/1/exe`
if [ -z "${TESTINIT##*"systemd"*}" ]; then
    echo -n "Stopping the Cisco Secure Client - Secure Firewall Posture agent... " 
    echo "Stopping the Cisco Secure Client - Secure Firewall Posture agent..." >> "${LOG}"
    echo "${SYSTEMCTL} stop ${SYSTEMD_UNIT}" >> "${LOG}"
    ${SYSTEMCTL} stop ${SYSTEMD_UNIT} >>  ${LOG}
    echo "done."
    echo "done." >> "${LOG}"

    echo ${SYSTEMCTL} disable ${SYSTEMD_UNIT} >>  "${LOG}"
    ${SYSTEMCTL} disable ${SYSTEMD_UNIT} >>  ${LOG} || ( echo "Warning: unable to disable service." )

    echo "rm ${SYSTEMD_UNIT_DIR}/${SYSTEMD_UNIT}" >> "${LOG}"
    rm -f ${SYSTEMD_UNIT_DIR}/${SYSTEMD_UNIT} || ( echo "Warning: unable to remove service script" )
fi


# update the VPNManifest.dat
POSTUREMANIFEST="ACManifestPOS.xml"

echo "${BINDIR}/manifesttool_posture -x ${CSC_INSTPREFIX} ${CSC_INSTPREFIX}/${POSTUREMANIFEST}" >> "${LOG}"
${BINDIR}/manifesttool_posture -x ${CSC_INSTPREFIX} ${CSC_INSTPREFIX}/${POSTUREMANIFEST} >> "${LOG}"

rm -f ${CSC_INSTPREFIX}/${POSTUREMANIFEST}

# Remove libraries from plugins directory

for f in ${PLUGINFILES}; do
    if [ -e ${PLUGINDIR}/$f ]; then
       echo "rm -rf ${PLUGINDIR}/$f" >> "${LOG}"
       rm -rf ${PLUGINDIR}/$f >> "${LOG}" 2>&1
    fi
done

# Remove hostscan downgrade support related directory.
HOSTSCAN_DOWNGRADE_SYMLINK="/opt/cisco/hostscan"
HOSTSCAN_DOWNGRADE_DIR="/opt/cisco/anyconnect/securefirewallposture/ac_hostscan"

if [ -e ${HOSTSCAN_DOWNGRADE_SYMLINK} ]; then
  echo "Removing AnyConnect Hostscan symlink ${HOSTSCAN_DOWNGRADE_SYMLINK}  " >> "${LOG}"
  echo "rm -rf ${HOSTSCAN_DOWNGRADE_SYMLINK}" >> "${LOG}"
  rm -rf ${HOSTSCAN_DOWNGRADE_SYMLINK} >> "${LOG}" 2>&1
fi

if [ -e ${HOSTSCAN_DOWNGRADE_DIR} ]; then
  echo "Removing AnyConnect Hostscan directory ${HOSTSCAN_DOWNGRADE_DIR}  " >> "${LOG}"
  echo "rm -rf ${HOSTSCAN_DOWNGRADE_DIR}" >> "${LOG}"
  rm -rf ${HOSTSCAN_DOWNGRADE_DIR} >> "${LOG}" 2>&1
fi

# Remove the main directory.
echo -n "Removing installed files... "
echo "Removing installed files... " >> "${LOG}"
if [ -d ${INSTPREFIX} ]; then
  echo "rm -rf ${INSTPREFIX}" >> "${LOG}"
  rm -rf ${INSTPREFIX} >> "${LOG}" 2>&1
fi
echo "done."
echo "done." >> "${LOG}"

echo "Successfully removed Cisco Secure Client - Secure Firewall Posture from the system." >> "${LOG}"
echo "Successfully removed Cisco Secure Client - Secure Firewall Posture from the system."

exit 0
