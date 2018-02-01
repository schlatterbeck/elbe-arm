RM=rm -f
CP=cp
MKDIR=mkdir -p
TAR=/bin/tar

ELBE_DIR=/data/project/project/elbe/initvm

elbe: elbe-sunxi-payload.xml
	elbe initvm submit --directory $(ELBE_DIR) elbe-sunxi-payload.xml

elbe-sunxi-payload.xml: elbe-sunxi.xml archive.tbz
	${CP} elbe-sunxi.xml elbe-sunxi-payload.xml
	elbe chg_archive elbe-sunxi-payload.xml archive.tbz

archive.tbz: sun8i-h3-bananapi-m2-plus.dtb uImage
	${RM} -r archivedir
	${MKDIR} archivedir/boot
	cp uImage archivedir/boot
	cp sun8i-h3-bananapi-m2-plus.dtb archivedir/boot/linux.dtb
	cp boot.cmd archivedir/boot
	cd archivedir && fakeroot ${TAR} cvjf ../archive.tbz .

