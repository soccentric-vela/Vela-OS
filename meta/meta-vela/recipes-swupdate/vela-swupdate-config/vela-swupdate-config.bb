SUMMARY = "SWUpdate runtime configuration and A/B OTA helper scripts for Vela Intel"
DESCRIPTION = "Installs swupdate.cfg, slot-detection scripts, web UI drop-in, and a one-shot boot-check service."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://swupdate.cfg \
    file://pre-install.sh \
    file://post-install.sh \
    file://swupdate-bootcheck.sh \
    file://swupdate-bootcheck.service \
    file://swupdate-webui.conf \
    file://swupdate-public.pem \
"

S = "${WORKDIR}"

inherit systemd

SYSTEMD_SERVICE:${PN} = "swupdate-bootcheck.service"
SYSTEMD_AUTO_ENABLE:${PN} = "enable"

RDEPENDS:${PN} = "swupdate bash util-linux"

do_install() {
    install -d ${D}${sysconfdir}/swupdate
    install -m 0644 ${WORKDIR}/swupdate.cfg \
                    ${D}${sysconfdir}/swupdate/swupdate.cfg

    install -d ${D}${libdir}/swupdate
    install -m 0755 ${WORKDIR}/pre-install.sh \
                    ${D}${libdir}/swupdate/pre-install.sh
    install -m 0755 ${WORKDIR}/post-install.sh \
                    ${D}${libdir}/swupdate/post-install.sh
    install -m 0755 ${WORKDIR}/swupdate-bootcheck.sh \
                    ${D}${libdir}/swupdate/swupdate-bootcheck.sh

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/swupdate-bootcheck.service \
                    ${D}${systemd_system_unitdir}/swupdate-bootcheck.service

    install -d ${D}${systemd_system_unitdir}/swupdate.service.d
    install -m 0644 ${WORKDIR}/swupdate-webui.conf \
                    ${D}${systemd_system_unitdir}/swupdate.service.d/webui.conf

    # SWUpdate RSA public key for signature verification
    install -m 0644 ${WORKDIR}/swupdate-public.pem \
                    ${D}${sysconfdir}/swupdate/swupdate-public.pem
}

FILES:${PN} += " \
    ${sysconfdir}/swupdate/ \
    ${libdir}/swupdate/ \
    ${systemd_system_unitdir}/swupdate-bootcheck.service \
    ${systemd_system_unitdir}/swupdate.service.d/ \
    ${sysconfdir}/swupdate/swupdate-public.pem \
"

FILES:${PN} += " \
    ${sysconfdir}/swupdate/ \
    ${libdir}/swupdate/ \
    ${systemd_system_unitdir}/swupdate-bootcheck.service \
    ${systemd_system_unitdir}/swupdate.service.d/ \
"
