# Configuration. May be specified in the environment or on the make
# commmand line via e.g. ``make ELBE_DIR=/usr/local/lib/elbe``

ifeq (${SDCARD_SIZE},)
#SDCARD_SIZE=1900MiB
SDCARD_SIZE=3724MiB
endif
export SDCARD_SIZE

ifeq (${BOOTLOADER},)
BOOTLOADER:=/usr/local/src/unpacked/u-boot-denx
endif

ifeq (${KERNEL},)
KERNEL:=/usr/local/src/unpacked/linux
endif

ifeq (${ELBE_DIR},)
ELBE_DIR:=/data/project/project/elbe/initvm
endif
export ELBE_DIR

ifeq (${DEBFULLNAME},)
DEBFULLNAME:=Anonymous
endif
export DEBFULLNAME

ifeq (${DEBEMAIL},)
DEBEMAIL:=anonymous@example.com
endif
export DEBEMAIL

ifeq (${DEBIAN_MIRROR_HOST},)
DEBIAN_MIRROR_HOST:=ftp.debian.org
endif
export DEBIAN_MIRROR_HOST

ifeq (${DEBIAN_MIRROR_PATH},)
DEBIAN_MIRROR_PATH:=/debian
endif
export DEBIAN_MIRROR_PATH

ifeq (${DEBIAN_MIRROR_PROTOCOL},)
DEBIAN_MIRROR_PROTOCOL:=http
endif
export DEBIAN_MIRROR_PROTOCOL

ifeq (${DEBIAN_SECURITY_MIRROR_HOST},)
DEBIAN_SECURITY_MIRROR_HOST:=security.debian.org
endif
export DEBIAN_SECURITY_MIRROR_HOST

ifeq (${DEBIAN_SECURITY_MIRROR_PATH},)
DEBIAN_SECURITY_MIRROR_PATH:=security.debian.org
endif
export DEBIAN_SECURITY_MIRROR_PATH

ifeq (${DEBIAN_SECURITY_MIRROR_PROTOCOL},)
DEBIAN_SECURITY_MIRROR_PROTOCOL:=${DEBIAN_MIRROR_PROTOCOL}
endif
export DEBIAN_SECURITY_MIRROR_PROTOCOL

ifeq (${DEBIAN_SECURITY_MIRROR_SUITE_SUFFIX},)
DEBIAN_SECURITY_MIRROR_SUITE_SUFFIX:=/updates
endif
export DEBIAN_SECURITY_MIRROR_SUITE_SUFFIX

ifeq (${DEBIAN_VOLATILE_MIRROR_HOST},)
DEBIAN_VOLATILE_MIRROR_HOST:=security.debian.org
endif
export DEBIAN_VOLATILE_MIRROR_HOST

ifeq (${DEBIAN_VOLATILE_MIRROR_PATH},)
DEBIAN_VOLATILE_MIRROR_PATH:=security.debian.org
endif
export DEBIAN_VOLATILE_MIRROR_PATH

ifeq (${DEBIAN_VOLATILE_MIRROR_PROTOCOL},)
DEBIAN_VOLATILE_MIRROR_PROTOCOL:=${DEBIAN_MIRROR_PROTOCOL}
endif
export DEBIAN_VOLATILE_MIRROR_PROTOCOL

ifeq (${DEBIAN_VOLATILE_MIRROR_SUITE_SUFFIX},)
DEBIAN_VOLATILE_MIRROR_SUITE_SUFFIX:=-updates
endif
export DEBIAN_VOLATILE_MIRROR_SUITE_SUFFIX

ifeq (${DEBIANSUITE},)
DEBIANSUITE:=stretch
endif
export DEBIANSUITE

# TARGET, usually specified on command line
# e.g. for Bananapi M2+ (and -EDU variant): Sinovoip_BPI_M2_Plus
ifeq (${TARGET},)
TARGET:=A20-OLinuXino-Lime
endif

# Graphics and Framebuffer console; these are expanded in boot.tpl

# Framebuffer console device
# Note that currently the templates put the serial console *last* so
# /dev/console will be the serial device. This is much easier to capture
# for debugging than the frambuffer console.
ifeq (${FB_CONSOLE},)
ifeq (${TARGET},orangepi_zero)
FB_CONSOLE=
else
FB_CONSOLE=console=tty0
endif
endif
export FB_CONSOLE

ifeq (${VIDEO_MODE_LINUX},)
ifeq (${TARGET},orangepi_zero)
VIDEO_MODE_LINUX=
else
VIDEO_MODE_LINUX=disp.screen0_output_mode=EDID:1280x1024p60
endif
endif
export VIDEO_MODE_LINUX

ifeq (${VIDEO_MODE_UBOOT},)
ifeq (${TARGET},orangepi_zero)
VIDEO_MODE_UBOOT=
else
VIDEO_MODE_UBOOT=video-mode=sunxi:1024x768-8@60,monitor=dvi,hpd=0,edid=1
endif
endif
export VIDEO_MODE_UBOOT

# HDMI Audio off, when on this may confuse some monitors
# Orange-Pi Zero doesn't have HDMI at all
# You may want to first ask EDID and set this to "EDID:0" but according
# to http://linux-sunxi.org/Kernel_arguments it seems that audio is
# shown to be supported when it definitely is not.
ifeq (${HDMI_AUDIO},)
ifeq (${TARGET},orangepi_zero)
HDMI_AUDIO=
else
HDMI_AUDIO=hdmi.audio=EDID:0
endif
endif
export HDMI_AUDIO

# systemd debug, you may want to set
# SYSTEMD_DEBUG=systemd.unit=rescue.target
export SYSTEMD_DEBUG

# Static mac address with /etc/udev/rules.d/75-static-mac
ifeq (${MAC_ADDRESS},)
MAC_ADDRESS=02:11:22:33:44:55
endif
export MAC_ADDRESS

DTBPATH:=${BOOTLOADER}/configs/${TARGET}_defconfig
# Allow override DTB on command-line or in environment
# But usually compute from bootloader config
ifeq (${DTB},)
DTB:=$(shell grep CONFIG_DEFAULT_DEVICE_TREE ${DTBPATH} | cut -d'"' -f2)
endif # DTB
export DTB

DTBCPU:=$(shell echo ${DTB} | cut -d- -f1)

ifeq (${CROSS_COMPILE},)
ifeq (${DTBCPU},bcm2835)
CROSS_COMPILE:=arm-linux-gnueabi-
else
CROSS_COMPILE:=arm-linux-gnueabihf-
endif
endif
export CROSS_COMPILE

ifeq (${DEBARCH},)
ifeq (${DTBCPU},bcm2835)
DEBARCH:=armel
else
DEBARCH:=armhf
endif
endif
export DEBARCH

ifeq (${HOST_NAME},)
HOST_NAME=${DTBCPU}
endif
export HOST_NAME

ifeq (${PROJECT},)
PROJECT=${DTBCPU}
endif
export PROJECT

ifeq (${UBOOTBIN},)
ifeq ($(findstring sun,${DTBCPU}),sun)
UBOOTBIN=u-boot-sunxi-with-spl.bin
else
UBOOTBIN=u-boot.bin
endif
endif

# ARCH is used by Linux kernel, we compute this from the given
# crosscompiler for the target.
ARCH:=$(shell echo ${CROSS_COMPILE} | cut -d- -f1)
export ARCH

# For serving a dynamically-generated debian repo we start a local
# web-server (python SimpleHTTPServer) on the given port
ifeq (${WEBSERVER_PORT},)
WEBSERVER_PORT:=9090
endif
export WEBSERVER_PORT

ifeq (${WEBSERVER_HOST},)
WEBSERVER_HOST=$(shell hostname --fqdn)
endif
export WEBSERVER_HOST

ifeq (${WEBSERVER_URL},)
WEBSERVER_URL:=http://${WEBSERVER_HOST}:${WEBSERVER_PORT}/debian-dist
endif
export WEBSERVER_URL

# These intentionally don't have ':=' assignment: They're expanded
# everytime: At start-time of make the respective files don't have the
# correct contents, they are created during kernel build.
KERNELRELEASE=$(shell cat ${KERNEL}/include/config/kernel.release)
KERNELREV=$(shell cat ${KERNEL}/.version)
KV=${KERNELRELEASE}_${KERNELRELEASE}
KR=${KERNELREV}

DEBPOOL:=debian-dist/pool
DEBDST:=debian-dist/dists/${DEBIANSUITE}
DEBSRC:=${DEBDST}/main/source
DEBBIN:=${DEBDST}/main/binary-${DEBARCH}
APTFTPCONF:=$(shell realpath apt-ftparchive.conf)

RM:=rm -f
CP:=cp
MKDIR:=mkdir -p
TAR:=/bin/tar
MKIMAGE:=${BOOTLOADER}/tools/mkimage

elbe: elbe-payload.xml .webserver.stamp
	elbe initvm submit --directory $(ELBE_DIR) elbe-payload.xml

elbe-payload.xml: elbe.xml archive.tbz
	${CP} elbe.xml elbe-payload.xml
	elbe chg_archive elbe-payload.xml archive.tbz

# The following 4 rules always force the generation of the .tmp file
# but the .xml file is only generated (timestamp updated) if it has
# changed. This prevents costly rebuilds but ensures the .xml is
# recreated if the TARGET variable changes.

%.tmp: %.tpl preprocess Makefile .sign-debs.${DEBARCH}.stamp FORCE
	env KERNELRELEASE=${KERNELRELEASE} ./preprocess $<

FORCE:

%.xml: %.tmp
	./move_if_change $< $@

%.cmd: %.tmp
	./move_if_change $< $@

75-static-mac: 75-static-mac.tmp
	./move_if_change $< $@

archive.tbz: u-boot-${TARGET}.bin boot.scr boot.cmd etc/network/interfaces \
    75-static-mac fw_printenv etc/fw_env.config
	${RM} -r archivedir
	${MKDIR} archivedir/boot
	${CP} u-boot-${TARGET}.bin archivedir/u-boot.bin
	${CP} boot.cmd archivedir/boot
	${CP} boot.scr archivedir/boot
	${CP} -a etc archivedir
	${MKDIR} archivedir/etc/udev/rules.d
	${CP} 75-static-mac archivedir/etc/udev/rules.d
	${MKDIR} archivedir/usr/bin
	${CP} fw_printenv archivedir/usr/bin
	cd archivedir && fakeroot ${TAR} cvjf ../archive.tbz .

boot.scr: boot.cmd
	$(MKIMAGE) -T script -C none -A arm -n 'bootscript' -d boot.cmd boot.scr

u-boot-${TARGET}.bin:
	make -C ${BOOTLOADER} clean
	make -C ${BOOTLOADER} ${TARGET}_config
	make -C ${BOOTLOADER}
	${CP} ${BOOTLOADER}/${UBOOTBIN} $@

# fw_printenv (for getting/setting u-boot environment from linux)
# shipped with debian doesn't work for sunxi, so we overwrite the
# debian-shipped binary with the one from current u-boot
# https://blog.night-shade.org.uk/2014/01/fw_printenv-config-for-allwinner-devices/
fw_printenv:
	make -C ${BOOTLOADER} envtools
	${CP} ${BOOTLOADER}/tools/env/fw_printenv $@

.kernel-build.${DEBARCH}.stamp: config-sunxi
	make -C ${KERNEL} distclean
	${CP} config-sunxi ${KERNEL}/.config
	make -C ${KERNEL} oldconfig
	make -C ${KERNEL} deb-pkg
	touch .kernel-build.${DEBARCH}.stamp

.kernel-package.${DEBARCH}.stamp ${DEBPOOL}: .kernel-build.${DEBARCH}.stamp \
    .gpg.stamp
	${RM} -r ${DEBSRC} ${DEBBIN}
	${MKDIR} ${DEBPOOL} ${DEBSRC} ${DEBBIN}
	${CP} gpg/pubring.asc debian-dist/pubring.asc
	${CP} ${KERNEL}/../linux-${KV}.orig.tar.gz                            \
	    ${KERNEL}/../linux-headers-${KV}-${KR}_${DEBARCH}.deb             \
	    ${KERNEL}/../linux-${KV}-${KR}_${DEBARCH}.changes                 \
	    ${KERNEL}/../linux-image-${KV}-${KR}_${DEBARCH}.deb               \
	    ${KERNEL}/../linux-libc-dev_${KERNELRELEASE}-${KR}_${DEBARCH}.deb \
	    ${KERNEL}/../linux-${KV}-${KR}.dsc ${DEBPOOL}
	cd debian-dist && dpkg-scansources pool . | gzip -9 - \
	    > dists/${DEBIANSUITE}/main/source/Sources.gz
	zcat ${DEBSRC}/Sources.gz > ${DEBSRC}/Sources
	touch .kernel-package.${DEBARCH}.stamp

# Note: Need to create Release file *after* signing deb packages
.sign-debs.${DEBARCH}.stamp: .kernel-package.${DEBARCH}.stamp .gpg.stamp
	dpkg-sig -g "--homedir gpg" --sign builder \
	    debian-dist/pool/linux-*_${DEBARCH}.deb
	cd debian-dist && dpkg-scanpackages -a ${DEBARCH} pool | gzip -9 - \
	    > dists/${DEBIANSUITE}/main/binary-${DEBARCH}/Packages.gz
	zcat ${DEBBIN}/Packages.gz > ${DEBBIN}/Packages
	cd ${DEBDST} && apt-ftparchive -c ${APTFTPCONF} release . \
	    > Release
	gpg --homedir gpg --yes --armor --output ${DEBDST}/Release.gpg \
	    --detach-sig ${DEBDST}/Release
	touch .sign-debs.${DEBARCH}.stamp

# Start local webserver for repository generated above
.webserver.stamp: .sign-debs.${DEBARCH}.stamp
	if [ -f .webserver.stamp ] ; then  \
	    kill $$(cat .webserver.stamp); \
	    ${RM} .webserver.stamp;        \
	fi
	python -m SimpleHTTPServer ${WEBSERVER_PORT} & \
	    echo $$! > $@
	sleep 2

show-kernel-version:
	@echo ${KERNELRELEASE} ${KERNELREV}

show-dtb:
	@echo ${DTB}

show-env:
	@echo TARGET=${TARGET} CROSS_COMPILE=${CROSS_COMPILE} ARCH=${ARCH}
	@echo DEBARCH=${DEBARCH} DTBCPU=${DTBCPU}
	@echo HOST_NAME=${HOST_NAME} PROJECT=${PROJECT}

GPG_KEY=$(shell gpg --list-secret-keys --homedir gpg | head -4 | tail -1)

# Oh, yes, this is really a hack. Note that all gpg commands nowaday
# start a gpg agent and creation of a key in batch mode fails if an
# agent is running.
.gpg.stamp gpg: gpg.cmd
	${RM} -r gpg
	${MKDIR} gpg
	chmod go-rwx gpg
	killall gpg-agent
	gpg --homedir ./gpg --batch --generate-key gpg.cmd
	gpg --homedir ./gpg --export --armor > gpg/pubring.asc
	touch .gpg.stamp

clean:
	if [ -f .webserver.stamp ] ; then  \
	    kill $$(cat .webserver.stamp); \
	    ${RM} .webserver.stamp;        \
	fi
	${RM} archive.tbz elbe-payload.xml boot.scr boot.cmd  \
	    elbe.xml boot.tmp elbe.tmp gpg.tmp 75-static-mac fw_printenv
	${RM} -r archivedir

clobber: clean
	${RM} -r ${DEBPOOL} gpg debian-dist
	${RM} .kernel-package.*.stamp .sign-debs.*.stamp \
	u-boot-*.bin gpg.cmd .kernel-build.*.stamp

.PHONY: clean clobber show-kernel-version show-dtb show-env FORCE
.PRECIOUS: .sign-debs.${DEBARCH}.stamp .kernel-package.${DEBARCH}.stamp \
    .kernel-build.${DEBARCH}.stamp gpg gpg.cmd .webserver.stamp
