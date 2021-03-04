#!/bin/bash

# called by dracut
check() {
    return 0
}

# called by dracut
depends() {
    echo bash udev-rules
    return 0
}

# called by dracut
install() {
    local _d
    inst_multiple chreipl lsreipl lszdev reboot sleep mount
    inst_script "$moddir/init.sh" /init
}
