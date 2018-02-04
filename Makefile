ifeq (${BOOTLOADER},)
BOOTLOADER:=/usr/local/src/unpacked/u-boot-denx
endif
ifeq (${KERNEL},)
KERNEL:=/usr/local/src/unpacked/linux
endif

# These intentionally don't have ':=' assignment: They're expanded
# everytime: At start-time of make the respective files don't have the
# correct contents, they are created during kernel build.
KERNELRELEASE=$(shell cat ${KERNEL}/include/config/kernel.release)
KERNELREV=$(shell cat ${KERNEL}/.version)
KV=${KERNELRELEASE}_${KERNELRELEASE}
KR=${KERNELREV}
KERNEL_IMAGE=vmlinuz-${KERNELRELEASE}

# For serving a dynamically-generated debian repo we start a local
# web-server (python SimpleHTTPServer) on the given port
WEBSERVER_PORT:=9090
WEBSERVER_URL:=http://$$(hostname --fqdn):${WEBSERVER_PORT}/debian-dist

# ARCH is used by Linux kernel
ARCH:=arm
export ARCH
DEBARCH:=armhf
DEBIANDIST:=stretch
DEBPOOL:=debian-dist/pool
DEBDST:=debian-dist/dists/${DEBIANDIST}
DEBSRC:=${DEBDST}/main/source
DEBBIN:=${DEBDST}/main/binary-${DEBARCH}
APTFTPCONF:=$(shell realpath apt-ftparchive.conf)

RM:=rm -f
CP:=cp
MKDIR:=mkdir -p
TAR:=/bin/tar
MKIMAGE:=${BOOTLOADER}/tools/mkimage

ifeq (${TARGET},)
TARGET:=A20-OLinuXino-Lime2
endif

# Allow override DTB on command-line or in environment
ifeq (${DTB},)
ifeq (${TARGET},A20-OLinuXino_MICRO)
DTB:=sun7i-a20-olinuxino-micro
else ifeq (${TARGET},A20-OLinuXino_MICRO-eMMC)
DTB:=sun7i-a20-olinuxino-micro-emmc
else ifeq (${TARGET},A20-OLinuXino-Lime)
DTB:=sun7i-a20-olinuxino-lime
else ifeq (${TARGET},A20-OLinuXino-Lime2)
DTB:=sun7i-a20-olinuxino-lime2
else ifeq (${TARGET},A20-OLinuXino-Lime2-eMMC)
DTB:=sun7i-a20-olinuxino-lime2-emmc
else ifeq (${TARGET},Sinovoip_BPI_M2_Plus)
DTB:=sun8i-h3-bananapi-m2-plus
endif
endif # No DTB

ifeq (${ELBE_DIR},)
ELBE_DIR:=/data/project/project/elbe/initvm
endif

elbe: elbe-sunxi-payload.xml .webserver.stamp \
    include/pkglist.xml include/copy-dtb.xml include/project.xml
	elbe initvm submit --directory $(ELBE_DIR) elbe-sunxi-payload.xml

elbe-sunxi-payload.xml: elbe-sunxi.xml archive.tbz
	${CP} elbe-sunxi.xml elbe-sunxi-payload.xml
	elbe chg_archive elbe-sunxi-payload.xml archive.tbz

archive.tbz: u-boot-sunxi-with-spl-${TARGET}.bin boot.scr
	${RM} -r archivedir
	${MKDIR} archivedir/boot
	${CP} u-boot-sunxi-with-spl-${TARGET}.bin archivedir/u-boot.bin
	${CP} boot.cmd archivedir/boot
	${CP} boot.scr archivedir/boot
	cd archivedir && fakeroot ${TAR} cvjf ../archive.tbz .

boot.scr: boot.cmd
	$(MKIMAGE) -T script -C none -A arm -n 'bootscript' -d boot.cmd boot.scr

boot.cmd:
	echo 'setenv bootargs console=ttyS0,115200' \
	     'root=/dev/mmcblk0p2 rootwait panic=10' > $@
	echo 'load mmc 0:1 0x43000000 linux.dtb ||' \
	     'load mmc 0:1 0x43000000 boot/linux.dtb' >> $@
	echo 'load mmc 0:1 0x42000000 ${KERNEL_IMAGE} ||' \
	     'load mmc 0:1 0x42000000 boot/${KERNEL_IMAGE}' >> $@
	echo 'bootz 0x42000000 - 0x43000000' >> $@

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
	    > dists/${DEBIANDIST}/main/source/Sources.gz
	zcat ${DEBSRC}/Sources.gz > ${DEBSRC}/Sources
	touch .kernel-package.stamp

# Note: Need to create Release file *after* signing deb packages
.sign-debs.stamp: .kernel-package.stamp gpg
	dpkg-sig -g "--homedir gpg" --sign builder debian-dist/pool/linux-*deb
	cd debian-dist && dpkg-scanpackages -a ${DEBARCH} pool | gzip -9 - \
	    > dists/${DEBIANDIST}/main/binary-${DEBARCH}/Packages.gz
	zcat ${DEBBIN}/Packages.gz > ${DEBBIN}/Packages
	cd ${DEBDST} && apt-ftparchive -c ${APTFTPCONF} release . \
            > Release
	gpg --homedir gpg --yes --armor --output ${DEBDST}/Release.gpg \
	    --detach-sig ${DEBDST}/Release
	touch .sign-debs.stamp

include/project.xml: include/project.tpl
	${CP} $< $@
	echo '      <url>'                    >> $@
	echo '        <binary>'               >> $@
	echo "          ${WEBSERVER_URL} ${DEBIANDIST} main" >> $@
	echo '        </binary>'              >> $@
	echo '        <key>'                  >> $@
	echo "          ${WEBSERVER_URL}/pubring.asc" >> $@
	echo '        </key>'                 >> $@
	echo '      </url>'                   >> $@
	echo '    </url-list>'                >> $@
	echo '  </mirror>'                    >> $@
	echo '  <noauth/>'                    >> $@
	echo '  <suite>${DEBIANDIST}</suite>' >> $@
	echo '</project>'                     >> $@

include/pkglist.xml: .sign-debs.stamp include/pkglist.tpl
	${CP} include/pkglist.tpl $@
	echo '  <pkg>linux-image-${KERNELRELEASE}</pkg>' >> $@
	echo '</pkg-list>' >> $@

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

GPG_KEY=$(shell gpg --list-secret-keys --homedir gpg | head -4 | tail -1)

# Oh, yes, this is really a hack. Note that all gpg commands nowaday
# start a gpg agent and creation of a key in batch mode fails if an
# agent is running.
gpg:
	${RM} -r gpg
	${MKDIR} gpg
	chmod go-rwx gpg
	${CP} gpg.gen gpg.genscript
	echo Name-Real: ${DEBFULLNAME} >> gpg.genscript
	echo Name-Email: ${DEBEMAIL}   >> gpg.genscript
	killall gpg-agent
	gpg --homedir ./gpg --batch --generate-key gpg.genscript
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

.PHONY: clean clobber show-kernel-version include/copy-dtb.xml boot.cmd
