ACTION=="add", SUBSYSTEM=="net", ATTR{dev_id}=="0x0", RUN+="/usr/bin/ip link set dev %k address {{MAC_ADDRESS}}"
