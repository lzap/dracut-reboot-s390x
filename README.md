# Reboot S390x helper dracut module

 A common provisioning workflow in the PXE world is to set boot order from network and then from disk and then control nodes via PXELinux configuration to either skip network boot and boot from HDD or to boot into OS installer for (re)provisioning.

Unfortunately, this is currently not possible on S390x platform. KVM/QEMU S390x virtual machines can be configured with only single boot device. One way to workaround the problem is to set VMs to always boot from network and create a custom init RAM disk that changes IPL configuration and immediately reboots. Libvirt does not persist the boot setting so the VM is booted from the desired device but on the next reboot, the VM boots from network again so the process can be repeated and VMs can be (re)provisioned just by modifying PXELinux configuration.

QEMU s390-ccw firmware contains PXELinux configuration parser which can be [utilized for flexible configuration](https://lukas.zapletalovi.com/2021/02/booting-s390x-libvirt-vms-over-network.html). With the dracut image and PXELinux configuration management, for example via [The Foreman](https://www.theforeman.org) open-source project, the PXE-like workflow can be achieved.

This was tested on Fedora and Red Hat Entetprise Linux, but it should work for any Linux-based OS. The libvirt hypervisor must be a S390x LPAR and all of the following commands and configuration must be performed on the S390x hypervisor.

## TFTP server setup

Create `/var/lib/tftpboot` directory and configure libvirt network to serve it via TFTP. Also make sure that that libvirt DHCP server returns filename option as `/` (root TFTP directory) which will make the s390-ccw firmware to search via UUID and MAC address.

    # virsh net-edit default
    <network>
      <!-- ... -->
      <ip address="192.168.122.1" netmask="255.255.255.0">
        <tftp root="/var/lib/tftpboot"/>
        <dhcp>
          <!-- ... -->
          <bootp file="/"/>
        </dhcp>
      </ip>
    </network>

Create `/var/lib/tftp/pxelinux.cfg` directory and place a new `default` fallback file with the following contents:

    # pxelinux
    default linux
    label linux
    kernel reboot-kernel.img
    initrd reboot-initrd.img
    #append rd.chreipl=ccw rd.chreipl=0.0.0000

The init ram disk which we are going to build in a minute sets IPL via `chreipl ccw 0.0.000` command by default, but this can be configured via one or more `rd.chreipl` kernel command line options. All those arguments are passed into the `chreipl` program.

For VMs which are supposed to be installed via OS installer, create PXELinux MAC-based configuration files (e.g. `/var/lib/tftpboot/pxelinux.cfg/00-AA-BB-CC-DD-EE-FF`):

    default linux
    label linux
    kernel anaconda-kernel.img
    initrd anaconda-initrd.img
    append ip=dhcp inst.repo=http://download.xxx.redhat.com/RHEL-8/8.1.0/BaseOS/s390x/os

Copy `anaconda-kernel.img` and `anaconda-initrd.img` from the BaseOS S390x kickstart installation tree (under `/images`).

If the TFTP directory should be managed via Foreman, use NFS to export the directory because Foreman cannot be installed on S390x architecture.

Check UNIX ownership, group, permissions and SELinux labels before reading the next part.

## Building the dracut image

Install s390 utilities:

    yum install s390utils-base

Copy current kernel into the TFTP directory:

    cp /boot/vmlinuz-$(uname -r) /var/lib/tftpboot/reboot-kernel.img

Copy contents of the `99-reboot-s390x` into `/usr/lib/dracut/modules.d` and perform the following command:

    dracut /var/lib/tftpboot/reboot-initrd.img -m "reboot-s390x" -f

Check UNIX ownership, group, permissions and SELinux labels before reading the next part.

## Boot a VM

Change PXELinux configuration either manually or via a provisioning tool like Foreman. To boot a VM into installer, use `anaconda-kernel` and the init RAM disk. To boot VM from local device, use `reboot-kernel` and the init RAM disk respectively.

## Authors

* Lukas Zapletal

## License

GNU GPL-2.0
