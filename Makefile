# Configuration. May be specified in the environment or on the make
# commmand line via e.g. ``make ELBE_DIR=/usr/local/lib/elbe``

ifeq (${SDCARD_SIZE},)
SDCARD_SIZE=1900MiB
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

ifeq (${DEBIAN_MIRROR},)
DEBIAN_MIRROR:=ftp.debian.org
endif
export DEBIAN_MIRROR

ifeq (${DEBIAN_MIRROR_PROTOCOL},)
DEBIAN_MIRROR_PROTOCOL:=http
endif
export DEBIAN_MIRROR_PROTOCOL

ifeq (${DEBIANSUITE},)
DEBIANSUITE:=stretch
endif
export DEBIANSUITE

# TARGET, usually specified on command line
# e.g. for Bananapi M2+ (and -EDU variant): Sinovoip_BPI_M2_Plus
ifeq (${TARGET},)
TARGET:=A20-OLinuXino-Lime2
endif

DTBPATH:=${BOOTLOADER}/configs/${TARGET}_defconfig
# Allow override DTB on command-line or in environment
# But usually compute from bootloader config
ifeq (${DTB},)
ifeq (${TARGET},A20-OLinuXino_MICRO-eMMC) # Workaround a bug in u-boot
DTB:=sun7i-a20-olinuxino-micro-emmc
else # No special TARGET
DTB:=$(shell grep CONFIG_DEFAULT_DEVICE_TREE ${DTBPATH} | cut -d'"' -f2)
endif # TARGET check
endif # DTB
export DTB

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

# ARCH is used by Linux kernel, we may compute this in the future from
# the given target. Same for CROSS_COMPILE and DEBARCH settings.
ARCH:=arm
export ARCH
CROSS_COMPILE=arm-linux-gnueabihf-
export CROSS_COMPILE
DEBARCH:=armhf
export DEBARCH
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

elbe: elbe-sunxi-payload.xml .webserver.stamp \
    include/pkglist.xml include/copy-dtb.xml include/project.xml
	elbe initvm submit --directory $(ELBE_DIR) elbe-sunxi-payload.xml

elbe-sunxi-payload.xml: elbe-sunxi.xml archive.tbz
	${CP} elbe-sunxi.xml elbe-sunxi-payload.xml
	elbe chg_archive elbe-sunxi-payload.xml archive.tbz

# The following 4 rules always force the generation of the .tmp file
# but the .xml file is only generated (timestamp updated) if it has
# changed. This prevents costly rebuilds but ensures the .xml is
# recreated if the TARGET variable changes.

%.tmp: %.tpl preprocess Makefile FORCE
	env KERNELRELEASE=${KERNELRELEASE} ./preprocess $<

FORCE:

%.xml: %.tmp
	./move_if_change $< $@

%.cmd: %.tmp
	./move_if_change $< $@

archive.tbz: u-boot-sunxi-with-spl-${TARGET}.bin boot.scr
	${RM} -r archivedir
	${MKDIR} archivedir/boot
	${CP} u-boot-sunxi-with-spl-${TARGET}.bin archivedir/u-boot.bin
	${CP} boot.cmd archivedir/boot
	${CP} boot.scr archivedir/boot
	cd archivedir && fakeroot ${TAR} cvjf ../archive.tbz .

boot.scr: boot.cmd
	$(MKIMAGE) -T script -C none -A arm -n 'bootscript' -d boot.cmd boot.scr

u-boot-sunxi-with-spl-${TARGET}.bin:
	make -C ${BOOTLOADER} clean
	make -C ${BOOTLOADER} ${TARGET}_config
	make -C ${BOOTLOADER}
	${CP} ${BOOTLOADER}/u-boot-sunxi-with-spl.bin $@

.kernel-build.stamp: kernel-config
	make -C ${KERNEL} distclean
	${CP} kernel-config ${KERNEL}/.config
	make -C ${KERNEL} oldconfig
	make -C ${KERNEL} deb-pkg
	touch .kernel-build.stamp

.kernel-package.stamp ${DEBPOOL}: .kernel-build.stamp gpg
	${RM} -r debian-dist
	${MKDIR} ${DEBPOOL} ${DEBSRC} ${DEBBIN}
	${CP} gpg/pubring.asc debian-dist/pubring.asc
	${CP} ${KERNEL}/../linux-${KV}.orig.tar.gz                            \
	    ${KERNEL}/../linux-headers-${KV}-${KR}_${DEBARCH}.deb             \
	    ${KERNEL}/../linux-${KV}-${KR}_${DEBARCH}.changes                 \
	    ${KERNEL}/../linux-image-${KV}-${KR}_${DEBARCH}.deb               \
	    ${KERNEL}/../linux-${KV}-${KR}.debian.tar.gz                      \
	    ${KERNEL}/../linux-libc-dev_${KERNELRELEASE}-${KR}_${DEBARCH}.deb \
	    ${KERNEL}/../linux-${KV}-${KR}.dsc ${DEBPOOL}
	cd debian-dist && dpkg-scansources pool . | gzip -9 - \
	    > dists/${DEBIANSUITE}/main/source/Sources.gz
	zcat ${DEBSRC}/Sources.gz > ${DEBSRC}/Sources
	touch .kernel-package.stamp

# Note: Need to create Release file *after* signing deb packages
.sign-debs.stamp: .kernel-package.stamp gpg
	dpkg-sig -g "--homedir gpg" --sign builder debian-dist/pool/linux-*deb
	cd debian-dist && dpkg-scanpackages -a ${DEBARCH} pool | gzip -9 - \
	    > dists/${DEBIANSUITE}/main/binary-${DEBARCH}/Packages.gz
	zcat ${DEBBIN}/Packages.gz > ${DEBBIN}/Packages
	cd ${DEBDST} && apt-ftparchive -c ${APTFTPCONF} release . \
            > Release
	gpg --homedir gpg --yes --armor --output ${DEBDST}/Release.gpg \
	    --detach-sig ${DEBDST}/Release
	touch .sign-debs.stamp

# A finetuning rule to copy correct dtb to /boot
# Note that this is marked a PHONY target to alway rebuild (DTB might
# have changed)
include/copy-dtb.xml:
	echo '<cp path="/usr/lib/linux-image-${KERNELRELEASE}/${DTB}.dtb">/boot/linux.dtb</cp>' > $@

# Start local webserver for repository generated above
.webserver.stamp: .sign-debs.stamp
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

GPG_KEY=$(shell gpg --list-secret-keys --homedir gpg | head -4 | tail -1)

# Oh, yes, this is really a hack. Note that all gpg commands nowaday
# start a gpg agent and creation of a key in batch mode fails if an
# agent is running.
gpg: gpg.cmd
	${RM} -r gpg
	${MKDIR} gpg
	chmod go-rwx gpg
	killall gpg-agent
	gpg --homedir ./gpg --batch --generate-key gpg.cmd
	gpg --homedir ./gpg --export --armor > gpg/pubring.asc

clean:
	if [ -f .webserver.stamp ] ; then  \
	    kill $$(cat .webserver.stamp); \
	    ${RM} .webserver.stamp;        \
	fi
	${RM} archive.tbz elbe-sunxi-payload.xml boot.scr \
            include/project.xml include/copy-dtb.xml

clobber: clean
	${RM} -r ${DEBPOOL}
	${RM} .kernel-package.stamp .sign-debs.stamp \
	u-boot-sunxi-with-spl-*.bin include/pkglist.xml

.PHONY: clean clobber show-kernel-version include/copy-dtb.xml \
    show-dtb FORCE
