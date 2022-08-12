#!/bin/sh

# This script is for setting up Gentoo on a Raspberry Pi 4
# Init System: OpenRC

set -e

# Variables

disk_name="sda"
grub_part_name="${disk_name}1"
boot_part_name="${disk_name}2"
rootfs_part_name="${disk_name}3"

timezone="America/New_York"
locale="en_US.UTF-8 UTF-8"

hostname="GentooPi"
local_dns_domain="lan"

net_interface_name_override=""

# Setup

source /etc/profile

mount "/dev/${boot_part_name}" /boot

emerge-webrsync

# Update profile

eselect profile list

echo "Verify profile. Select number corresponding to target profile."
echo "Enter '0' for no change"
echo -n "Profile: "

read profile_select
if [ $profile_select -ne 0 ]; then
    echo "Selecting profile $profile_select"
    eselect profile set $profile_select
else
    echo "Profile unchanged"
fi
env-update && source /etc/profile

# Update/Install software

emerge --verbose --update --deep --newuse @world

emerge -q app-editors/vim

# Set timezone

echo "${timezone}" > /etc/timezone
emerge --config sys-libs/timezone-data

# Set locale

eselect locale list

if [ -n "${locale}" ]; then
    echo "${locale}" >> /etc/locale.gen
    locale-gen
    eselect locale list
    echo "Select a locale. Enter '0' for no change"
    echo -n "Locale: "
    read locale_select
    if [ "${locale_select}" -ne 0 ]; then
        eselect locale set "${locale_select}"
    else
        echo "Locale unchanged"
    fi
else
    echo "Skiping locale update"
fi

# Install Linux firmware and configure kernel

mkdir -p /etc/portage/package.license
echo "sys-kernel/linux-firmware @BINARY-REDISTRIBUTABLE" >> /etc/portage/package.license/kernel
emerge -q --autounmask-continue sys-kernel/gentoo-sources sys-kernel/genkernel

#emerge -q app-arch/lzop app-arch/lz4

eselect kernel list
echo -e "Select a kernel by number: "
read kernel_select
eselect kernel set "${kernel_select}"

# emerge -q sys/pciutils

# Gentoo-specific kernel options
# Gentoo Linux --->
#   Generic Driver Options --->
#     [*] Gentoo Linux support
#     [*]   Linux dynamic and persistent device naming (userspace devfs) support
#     [*]   Select options required by Portage features
#         Support for init systems, system and service managers  --->
#           [*] OpenRC, runit and other script based systems and managers
#           [*] systemd
#           Note: choose the init system you plan on using

# Kernel config for GPT (Partition Table)
# enable block layer
# enable parition types
# activate advanced partition sleection and EFI GUID support

# Kernel config for Podman:
#General setup  --->
#    -*- Namespaces support  --->
#        [*]  User namespace
#File systems  --->
#    <*> FUSE (Filesystem in Userspace) support
#    <*> Overlay filesystem support
#Device Drivers --->
#    -*- Network device support --->
#        -*- Network core driver support --->
#            <*/M> Universal TUN/TAP device driver support

cd /usr/src/linux
make menuconfig
make && make modules_install && make install
cd /

genkernel --install --kernel-config=/usr/src/linux/.config initramfs
ls /boot/initramfs*

echo "hostname=\"${hostname}\"" > /etc/conf.d/hostname

echo "dns_domain_lo=\"${local_dns_domain}\""

# Configure Network

emerge -q --noreplace net-misc/netifrc

