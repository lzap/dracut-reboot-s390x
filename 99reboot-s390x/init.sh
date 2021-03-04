#!/bin/bash
PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH

[ ! -d /proc/self ] && \
    mount -t proc -o nosuid,noexec,nodev proc /proc >/dev/null

if [ "$?" != "0" ]; then
    echo "Cannot mount proc on /proc! Compile the kernel with CONFIG_PROC_FS!"
    exit 1
fi

[ ! -d /sys/kernel ] && \
    mount -t sysfs -o nosuid,noexec,nodev sysfs /sys >/dev/null

if [ "$?" != "0" ]; then
    echo "Cannot mount sysfs on /sys! Compile the kernel with CONFIG_SYSFS!"
    exit 1
fi

if [ ! -d /dev ]; then
    mount -t devtmpfs -o mode=0755,noexec,nosuid,strictatime devtmpfs /dev >/dev/null
fi

if [ "$?" != "0" ]; then
    echo "Cannot mount devtmpfs on /dev! Compile the kernel with CONFIG_DEVTMPFS!"
    exit 1
fi

# Parse kernel command line
ARGS_CMDLINE=""
set -- $(cat /proc/cmdline)
for x in "$@"; do
    case "$x" in
        rd.chreipl=*)
        ARGS_CMDLINE="$ARGS_CMDLINE ${x#rd.chreipl=}"
        ;;
    esac
done

echo "Available devices:"
lszdev
echo "Current IPL:"
lsreipl
ARGS=${ARGS_CMDLINE:-ccw 0.0.0000}
echo "Changing to $ARGS"
chreipl ${ARGS}
sleep 1
echo "Rebooting..."
reboot -nf
