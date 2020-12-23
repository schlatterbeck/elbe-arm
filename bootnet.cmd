# Boot script for A20-OLinuXino_MICRO
#video-mode=sunxi:1024x768-8@60,monitor=dvi,hpd=0,edid=1
setenv bootargs console=tty0 console=ttyS0,115200  hdmi.audio=EDID:0 disp.screen0_output_mode=EDID:1280x1024p60 root=/dev/nfs rootfstype=nfs ip=dhcp nfsroot=10.23.5.5:/data/project/project/rootfs/A20-OLinuXino_MICRO,nfsvers=3 rootpath=/data/project/project/rootfs/A20-OLinuXino_MICRO rootwait panic=10
setenv overlay max9744-i2c2 rda5807-i2c2 simple-sound
bootp
tftpboot 0x43000000 tftpboot/micro-dtb
fdt addr 0x43000000
fdt resize
for ov in ${overlay}; do
    echo overlaying ${ov}
    tftpboot 0x4300F000 tftpboot/dtbo/${ov}.dtbo && fdt apply 0x4300F000
done
#tftpboot 0x42000000 tftpboot/micro-zImage
bootz 0x42000000 - 0x43000000
