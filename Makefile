RM:=rm -f
CP:=cp
MKDIR:=mkdir -p
TAR:=/bin/tar
MKIMAGE:=/usr/local/src/unpacked/u-boot-denx/tools/mkimage

ifeq (${TARGET},)
TARGET:=A20-OLinuXino-Lime2
endif

ifeq (${TARGET},A20-OLinuXino-MICRO)
DTB:=sun7i-a20-olinuxino-micro
else ifeq (${TARGET},A20-OLinuXino-MICRO-eMMC)
DTB:=sun7i-a20-olinuxino-micro-emmc
else ifeq (${TARGET},A20-OLinuXino-Lime2)
DTB:=sun7i-a20-olinuxino-lime2
else ifeq (${TARGET},A20-OLinuXino-Lime2-eMMC)
DTB:=sun7i-a20-olinuxino-lime2-emmc
else ifeq (${TARGET},Sinovoip_BPI_M2_Plus)
DTB:=sun8i-h3-bananapi-m2-plus
endif

ELBE_DIR=/data/project/project/elbe/initvm

elbe: elbe-sunxi-payload.xml
	elbe initvm submit --directory $(ELBE_DIR) elbe-sunxi-payload.xml

elbe-sunxi-payload.xml: elbe-sunxi.xml archive.tbz
	${CP} elbe-sunxi.xml elbe-sunxi-payload.xml
	elbe chg_archive elbe-sunxi-payload.xml archive.tbz

archive.tbz: ${DTB}.dtb uImage u-boot-sunxi-with-spl-${TARGET}.bin boot.scr
	${RM} -r archivedir
	${MKDIR} archivedir/boot
	cp uImage archivedir/boot
	cp u-boot-sunxi-with-spl-${TARGET}.bin archivedir/boot/u-boot.bin
	cp ${DTB}.dtb archivedir/boot/linux.dtb
	cp boot.cmd archivedir/boot
	cp boot.scr archivedir/boot
	cd archivedir && fakeroot ${TAR} cvjf ../archive.tbz .

boot.scr: boot.cmd
	$(MKIMAGE) -T script -C none -A arm -n 'bootscript' -d boot.cmd boot.scr

