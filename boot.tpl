# Boot script for {{TARGET}}
{{VIDEO_MODE_UBOOT}}
setenv bootargs {{FB_CONSOLE}} console=ttyS0,115200 {{SYSTEMD_DEBUG}} {{HDMI_AUDIO}} {{VIDEO_MODE_LINUX}} root=/dev/mmcblk0p2 rootwait panic=10
load {{BOOT_DEVICETYPE}} {{BOOT_DEVICENUM}}:{{BOOT_PARTITION}} {{BOOT_DTB_ADDRESS}} linux.dtb || load {{BOOT_DEVICETYPE}} {{BOOT_DEVICENUM}}:{{BOOT_PARTITION}} {{BOOT_DTB_ADDRESS}} boot/linux.dtb
fdt addr {{BOOT_DTB_ADDRESS}}
fdt resize
if load {{BOOT_DEVICETYPE}} {{BOOT_DEVICENUM}}:{{BOOT_PARTITION}} {{BOOT_OVERLAY_ADDRESS}} overlay.cmd && env import -t {{BOOT_OVERLAY_ADDRESS}} ${filesize} && test -n ${overlay}; then
    for ov in ${overlay}; do
        echo overlaying ${ov}
        load {{BOOT_DEVICETYPE}} {{BOOT_DEVICENUM}}:{{BOOT_PARTITION}} {{BOOT_OVERLAY_ADDRESS}} dtbo/${ov}.dtbo && fdt apply {{BOOT_OVERLAY_ADDRESS}}
    done
fi
load {{BOOT_DEVICETYPE}} {{BOOT_DEVICENUM}}:{{BOOT_PARTITION}} {{BOOT_KERNEL_ADDRESS}} vmlinuz-{{KERNELRELEASE}} || load {{BOOT_DEVICETYPE}} {{BOOT_DEVICENUM}}:{{BOOT_PARTITION}} {{BOOT_KERNEL_ADDRESS}} boot/vmlinuz-{{KERNELRELEASE}}
bootz {{BOOT_KERNEL_ADDRESS}} - {{BOOT_DTB_ADDRESS}}

