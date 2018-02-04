setenv bootargs console=ttyS0,115200 root=/dev/mmcblk0p2 rootwait panic=10
load mmc 0:1 0x43000000 linux.dtb || load mmc 0:1 0x43000000 boot/linux.dtb
load mmc 0:1 0x42000000 vmlinuz-{{KERNELRELEASE}} || load mmc 0:1 0x42000000 boot/vmlinuz-{{KERNELRELEASE}}
bootz 0x42000000 - 0x43000000

