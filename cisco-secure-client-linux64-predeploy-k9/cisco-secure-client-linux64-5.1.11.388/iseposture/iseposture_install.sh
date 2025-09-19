#!/bin/sh
#

BASH_BASE_SIZE=0x00002054
CISCO_AC_TIMESTAMP=0x00000000689e540d
CISCO_AC_OBJNAME=iseposture_install.sh                                                                                                                                                                                                                                           
# BASH_BASE_SIZE=0x00000000 is required for signing
# the comment is after or else the code signing tool will find the comment

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

AC_INSTPREFIX="/opt/cisco/anyconnect"
AC_ISEPOSTURE_PROFILEDIR="${AC_INSTPREFIX}/iseposture"
AC_ISEPOSTURE_SCRIPTDIR="${AC_ISEPOSTURE_PROFILEDIR}/scripts"

CSC_INSTPREFIX="/opt/cisco/secureclient"
CSC_BINDIR="${CSC_INSTPREFIX}/bin"
CSC_LIBDIR="${CSC_INSTPREFIX}/lib"
CSC_PLUGINDIR="${CSC_BINDIR}/plugins"
CSC_ISEPOSTURE_PROFILEDIR="${CSC_INSTPREFIX}/iseposture"
CSC_ISEPOSTURE_SCRIPTDIR="${CSC_ISEPOSTURE_PROFILEDIR}/scripts"

ISEBINFILES="csc_iseposture csc_iseagentd iseposture_uninstall.sh manifesttool_iseposture"
ISELIBFILES="libacise.so"
ISEPLUGINFILES="libacisectrl.so libaciseshim.so"
ISEPOSTUREMANIFEST="ACManifestISEPosture.xml"
ISEMIGRATIONFILES="ISEPostureCFG.xml ConnectionData.xml DGCacheRecords.xml ISEPreferences.xml"
VPNMANIFEST="${CSC_INSTPREFIX}/ACManifestVPN.xml"

LOGFNAME=`date "+csc-linux64-5.1.11.388-iseposture-%H%M%S%d%m%Y.log"`
CLIENTNAME="Cisco Secure Client - ISE Posture"
CURRENTDIR=`dirname $0 2> /dev/null`

INST_BINDIR="${CURRENTDIR}/bin"
INST_PLUGINDIR="${INST_BINDIR}/plugins"
INST_LIBDIR="${CURRENTDIR}/lib"

ARG_NO_LICENSE=0

if [ "x$1" = "x--no-license" ]; then
    ARG_NO_LICENSE=1
fi

echo "Installing ${CLIENTNAME}..."
echo "Installing ${CLIENTNAME}..." > /tmp/${LOGFNAME}
echo `whoami` "invoked $0 from " `pwd` " at " `date` >> /tmp/${LOGFNAME}

# Check for root privileges
if [ `id | sed -e 's/(.*//'` != "uid=0" ]; then
  echo "Sorry, you need super user privileges to run this script."
  echo "Sorry, you need super user privileges to run this script." >> /tmp/${LOGFNAME}
  exit 1
fi

# ISE Posture requires VPN to be installed. We check the presence of the vpn manifest file to check if it is installed.
if [ ! -f ${VPNMANIFEST} ]; then
    echo "AnyConnect VPN should be installed before ISE Posture installation. Install Cisco Secure Client - AnyConnect VPN to proceed."
    echo "Exiting now."
    echo "AnyConnect VPN should be installed before ISE Posture installation. Install Cisco Secure Client - AnyConnect VPN to proceed." >> /tmp/${LOGFNAME}
    echo "Exiting now." >> /tmp/${LOGFNAME}
    exit 1
fi

failed=false
# version of ise posture being installed has to be same as installed VPN version
if [ -f "${CURRENTDIR}/${ISEPOSTUREMANIFEST}" ] && [ -f ${VPNMANIFEST} ]; then
    VPNVERSION=$(awk -F"\"" '/file version/ { print $2 }' ${VPNMANIFEST})
    ISECURRVERSION=$(awk -F"\"" '/file version/ { print $2 }' ${CURRENTDIR}/${ISEPOSTUREMANIFEST})

    vpn_ver="$(csc_vercmp "$VPNVERSION" "$ISECURRVERSION")"
    if [ "$vpn_ver" != same ]; then
     failed=true
    fi
fi

if [ "$failed" = true ]; then
    echo "Please use ise posture installer from Cisco Secure Client package with version ${VPNVERSION} for the installation"
    echo "Please use ise posture installer from Cisco Secure Client package with version ${VPNVERSION} for the installation" >> /tmp/${LOGFNAME}
    echo "Exiting now."
    echo "Exiting now." >> /tmp/${LOGFNAME}
    exit 1
fi

if [ "x${ARG_NO_LICENSE}" = "x1" ]; then
    echo "Skipping license text ..."
else
    if [ -f "license.txt" ]; then
        cat ./license.txt
        echo
        echo -n "Do you accept the terms in the license agreement? [y/n] "
        read LICENSEAGREEMENT
        while :
        do
          case ${LICENSEAGREEMENT} in
               [Yy][Ee][Ss] | [Yy])
                       echo "You have accepted the license agreement."
                       echo "Please wait while ${CLIENTNAME} is being installed..."
                       break
                       ;;
               [Nn][Oo] | [Nn])
                       echo "The installation was cancelled because you did not accept the license agreement."
                       echo "The installation was cancelled because you did not accept the license agreement." >> /tmp/${LOGFNAME}
                       exit 1
                       ;;
               *)
                       echo "Please enter either \"y\" or \"n\"."
                       read LICENSEAGREEMENT
                       ;;
          esac
        done
    else
        echo "License file not found. Aborting installation."
        echo "License file not found. Aborting installation." >> /tmp/${LOGFNAME}
        exit 1
    fi
fi
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

echo "Creating directories... "
echo "Creating directories... " >> /tmp/${LOGFNAME}

if [ "x${INSTALL}" = "x" ]; then
    echo "Unable to find install command. Aborting installation."
    echo "Unable to find install command. Aborting installation." >> /tmp/${LOGFNAME}
    exit 1
fi

# Make sure destination directories exist
echo "Installing "${CSC_BINDIR} >> /tmp/${LOGFNAME}
${INSTALL} -d ${CSC_BINDIR} || exit 1
echo "Installing "${CSC_LIBDIR} >> /tmp/${LOGFNAME}
${INSTALL} -d ${CSC_LIBDIR} || exit 1
echo "Installing "${CSC_PLUGINDIR} >> /tmp/${LOGFNAME}
${INSTALL} -d ${CSC_PLUGINDIR} || exit 1
echo "Installing "${CSC_ISEPOSTURE_PROFILEDIR} >> /tmp/${LOGFNAME}
${INSTALL} -d ${CSC_ISEPOSTURE_PROFILEDIR} || exit 1
echo "Installing "${CSC_ISEPOSTURE_SCRIPTDIR} >> /tmp/${LOGFNAME}
${INSTALL} -d ${CSC_ISEPOSTURE_SCRIPTDIR} || exit 1

echo "done."
echo "done." >> /tmp/${LOGFNAME}

# Migrate /opt/cisco/anyconnect/iseposture/ files to /opt/cisco/secureclient/iseposture/
for file in ${ISEMIGRATIONFILES}; do
    if [ -f ${AC_ISEPOSTURE_PROFILEDIR}/$file ] &&
       [ ! -f ${CSC_ISEPOSTURE_PROFILEDIR}/$file ]; then
      echo "Migrating "${AC_ISEPOSTURE_PROFILEDIR}/$file >> /tmp/${LOGFNAME}
      cp -f ${AC_ISEPOSTURE_PROFILEDIR}/$file ${CSC_ISEPOSTURE_PROFILEDIR}/ >/dev/null 2>&1
    fi
done
if [ -d "${AC_ISEPOSTURE_SCRIPTDIR}" ]; then
    echo "Migrating "${AC_ISEPOSTURE_SCRIPTDIR}/ >> /tmp/${LOGFNAME}
    tar cf - -C ${AC_ISEPOSTURE_SCRIPTDIR} . | (cd ${CSC_ISEPOSTURE_SCRIPTDIR}; tar --skip-old-files -x -f -)
fi

echo "Copying files... "
echo "Copying files... " >> /tmp/${LOGFNAME}

for f in ${ISEBINFILES}; do
    echo "Installing "${INST_BINDIR}/$f >> /tmp/${LOGFNAME}
    ${INSTALL} -o root -m 755 ${INST_BINDIR}/$f ${CSC_BINDIR} || exit 1
done

for f in ${ISELIBFILES}; do
    echo "Installing "${INST_LIBDIR}/$f >> /tmp/${LOGFNAME}
    ${INSTALL} -o root -m 755 ${INST_LIBDIR}/$f ${CSC_LIBDIR} || exit 1
done

for f in ${ISEPLUGINFILES}; do
    echo "Installing "${INST_PLUGINDIR}/$f >> /tmp/${LOGFNAME}
    ${INSTALL} -o root -m 755 ${INST_PLUGINDIR}/$f ${CSC_BINDIR} || exit 1
    mv -f ${CSC_BINDIR}/$f ${CSC_PLUGINDIR} || exit 1
done

# update manifest
echo "Updating AC manifest." >> /tmp/${LOGFNAME}

${INSTALL} -o root -m 755 ${CURRENTDIR}/${ISEPOSTUREMANIFEST} ${CSC_INSTPREFIX} >> /tmp/${LOGFNAME}
${INST_BINDIR}/manifesttool_iseposture -i ${CSC_INSTPREFIX} ${CSC_INSTPREFIX}/${ISEPOSTUREMANIFEST} >> /tmp/${LOGFNAME}

# enable GUI launch at login
if [ -f "${CSC_BINDIR}/acinstallhelper" ]; then
    echo "Enabling Cisco Secure Client - GUI launch at login." >> /tmp/${LOGFNAME}
    ${CSC_BINDIR}/acinstallhelper -launchAtLogin -enable
fi

echo "done."
echo "done." >> /tmp/${LOGFNAME}

echo "${CLIENTNAME} is installed successfully."
echo "${CLIENTNAME} is installed successfully." >> /tmp/${LOGFNAME}

# move the logfile out of the tmp directory
mv /tmp/${LOGFNAME} ${CSC_INSTPREFIX}/.

exit 0


  +S!cV!j!dqeayIVDMPT!A!kfkjvddSBJJJ!V!eznRGBF r0�n0�V�G�4�	��c��`Ji0	*�H�� 0i10	UUS10U
DigiCert, Inc.1A0?U8DigiCert Trusted G4 Code Signing RSA4096 SHA384 2021 CA10240329000000Z270404235959Z0v10	UUS10UMassachusetts10U
Boxborough10U
Cisco Systems, Inc.10UCisco Systems, Inc.0�"0	*�H�� � 0�
� �໼OӋ���;��h;O#�~&��x�RZ�c����H�%�r���%7������/�?x����T�ȼ*~SN\%��ļs\bڟ��"|=L��n��c�<��ɕң����lߦ�͜��H�?��0S�X��K�XZ�����L�1�O�m���wi�s�p�.�,��H��?U+�+�r`�T#'9_џ1>15#=�bK���w���.:���@�I/���n���u�5-�}Q��*��[H��NA�����I��i����<��u�'��������ˇ?f)�._`l��o��_��f���
��;M9��ܡ<]ҍ��|��ͲLX 6����6�+�֓�?,X�i�1��D��'tk���EF=!��c� ��PK��w4��3Hv�o[]��I̵� ���Lo9������еT���_j��t���$#&G�dQ
�]�FD�����r�U�Tb�����-4A������f`��v�YA�F�������.�>`��W��S���i���ޔ� ��0��0U#0�h7��;�_���a{�e�NB0U�t�b=_r�3�;k���*0�0>U 70503g�0)0'+http://www.digicert.com/CPS0U��0U%0
+0��U��0��0S�Q�O�Mhttp://crl3.digicert.com/DigiCertTrustedG4CodeSigningRSA4096SHA3842021CA1.crl0S�Q�O�Mhttp://crl4.digicert.com/DigiCertTrustedG4CodeSigningRSA4096SHA3842021CA1.crl0��+��0��0$+0�http://ocsp.digicert.com0\+0�Phttp://cacerts.digicert.com/DigiCertTrustedG4CodeSigningRSA4096SHA3842021CA1.crt0	U0 0	*�H�� � ���q&~	]梦F��7V��7���ˌ��y���N��j��z����GGE@��G��f2_Qc��"w�U@�+򚑙��Q߂&�k>Q�!��ෑ��L8����)z�0�����vo���r���iFBa����9f���0\M�q�oE>Gg޽�����c�OZ��咝''�lo���������
<�=�
����P�b$�1��gn�mG��?y�X PF� �.��ҀP�;0̷�+��U��8Q
u���s��r���}�x#b�A���ֳ�_�A�������Џ�i��ʧ�O8�F=�]Θ��u��3a�r1���!�����6�g���L^�iD�lX��M��.F�����|�tg�-�x�a�4�ZZ8(�4�JoiG�M�v��>�6ނ�4)؜ ��\���H��y���&Wq_e����;����D�*2�ћ�.`����m��յ���0�S��`�L�<0,�Ѧ]��Y���1�DA6��� �0��0����@�`ҜL�^ͩ����0	*�H�� 0b10	UUS10U
DigiCert Inc10Uwww.digicert.com1!0UDigiCert Trusted Root G40210429000000Z360428235959Z0i10	UUS10U
DigiCert, Inc.1A0?U8DigiCert Trusted G4 Code Signing RSA4096 SHA384 2021 CA10�"0	*�H�� � 0�
� մ/B�(�x�]�9Y��B�3��=��pŻą&0���h�\��4$�KO�xC������gRO�W�����́>Mp$d���}4}L�WkC����;���GZ�L� %�Ӌ������	�e����I5�=Q�!xE.��,�����IpB2�����eh��ML�HRh��W]�e��O�,H�V�5��.�� �7���|��2������t��9��`��ֹ�1�ܭ����#GG��n��m���jg-ҽD����;	�Ǜ2Z��j`T�I����\�o�&��ղ�8��Α����o�a4\��E(�6*f(_�s΋&%���\�L�b�^3����
��+��6y���u�e̻�HP�w���P�F�aX��|<�(�9��ԷS��G�u0��0�v�[K]taM?�v޿X�r)A���m&vhAX��&+�MY�xρJ>@G_ɁPs�#!Y`�dT��!�8|f�x8E0�O�cOL��SA|X=G����2	�l<V ��Y0�U0U�0� 0Uh7��;�_���a{�e�NB0U#0�����q]dL�.g?纘�O0U��0U%0
+0w+k0i0$+0�http://ocsp.digicert.com0A+0�5http://cacerts.digicert.com/DigiCertTrustedRootG4.crt0CU<0:08�6�4�2http://crl3.digicert.com/DigiCertTrustedRootG4.crl0U 00g�0g�0	*�H�� � :#D=�v:��V���H4�,��tf��r� ʯl0'��D�K���|&�7�:]Hm��?I�'��EP������v~7q�"�Z�����j�� ��Py��������H~�؀�a��V���v���_C�>��v9=�ԙ�J�(�_&��XH���'?���v���`\�������9�8N�n�6���!SZ���j�>�C�3�O8�����Tm�]@3|╲�!usR�F��4��K��ov7,�?�&����C�� �p�����)5\�8U�7��	���1�.\9qᾜ�
�&g���N_�z�I�.�t���<�����V+#����{pk栺�:?E����R�A�H�K�M�D@��(���V*/�d<3��(�<ˏ��;��{���˷�w��(?���/"lA��\f�l�ņ��&3K��jj@0HK4�Q ����Ym�P+�J�����t���R����H!�W;���E��an�h�&`��ȯ����c:�VxN  :���*��}��	w��5X�}Z�}�͠B�B(�!h�򶄃�+�szW�za)���� ��>��ut⹡���4�屠�����H�l�颻@���a���业�S��P�d"�{߹�N�,N��t�q��+�!0��4I`��6�C�C�ݽ��wQr�W���W
����x6>�o��]��;w�͚�n�X���Qc���G���V�w�`Y�{m��z�kF�s뎃���OZ�m���(�G� 
���V�d�U�"'ald#�ь�Cy{�"��:S��)�L%L���UV`:�V,�Ȱ4i?r���RǊ�qn-�zCt߳���~RQ�!.�Ǧ[H�n�ܯ�o�lM�.%;%�7���w�.����\�$
���,y��*>���<�*�h#�<�$&.��F��97� �<?��7�
��&�-7�ځ�zF+ږZ��Bs�RW�*��ʘ��p������ϛ��u����?�ц��
�#m� ;���acIj&CFe�}��Rٷf"� ���߳P  **��b#F�s��F���9l�ȓ�T�;�Kh��=��9������`��˵��V���}r	~9h�;�e�����.�&��f<e�=��V��a��js��؆��߹�eq�3}�Dz�0�����ArB%�L�[�p�îo:�����Q2�1n�$O4r�`�Pvz6PE)�����>'�@ͪ.V��}�M��H��J�c|�RqT��+B?)l2�y�6%I���Z�
S,��GEF���Dc䲡������)X���,��-ll���I�'�.�ɻ��0�%���8���Pt�z ���k"���(zbH��UU����Oz>��;w�=���I�e]7��W������JY�V�R���,����r\;�+��k!ZZ�3V����5�iY��.�P�a�����U_>�VR��ݩW�7�"�2K�;�S���W���.)A�B�C���uh����q�����r�����(TW�D�R/��yɫ�*0��z��'դ!�rƑcO��^��C�