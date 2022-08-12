#!/bin/sh

set -e

disk_name="sda"
grub_part_name="${disk_name}1"
boot_part_name="${disk_name}2"
rootfs_part_name="${disk_name}3"

rootfs_mount_path="/mnt/gentoo"

gentoo_stage_url="https://bouncer.gentoo.org/fetch/root/all/releases/arm64/autobuilds/20220807T233150Z/stage3-arm64-musl-hardened-20220807T233150Z.tar.xz"
gentoo_stage_filename=$(basename ${gentoo_stage_url})

make_conf_path="make.conf"

# Wipe disk
wipefs -a "/dev/${disk_name}"

# Create partitions
parted --script -a opt "/dev/${disk_name}" -- \
    mklabel gpt \
    unit mib \
    mkpart primary 1 3 \
    name 1 grub \
    set 1 bios_grub on \
    mkpart primary 3 131 \
    name 2 boot \
    mkpart primary 131 -1 \
    name 3 rootfs \
    print

sleep 0.5

# Create file allocation tables
mkfs.fat -F 32 "/dev/${boot_part_name}"
mkfs.ext4 "/dev/${rootfs_part_name}"

# Mount rootfs
mkdir -p "${rootfs_mount_path}"
mount "/dev/${rootfs_part_name}" "${rootfs_mount_path}"

# Extract Gentoo into rootfs
wget "${gentoo_stage_url}"
tar xpvf "${gentoo_stage_filename}" --xattrs-include='*.*' --numeric-owner -C "${rootfs_mount_path}"
rm -f "${gentoo_stage_filename}"

# Prepare configs
cp ${make_conf_path} "${rootfs_mount_path}/etc/portage/make.conf"

mkdir -p "${rootfs_mount_path}/etc/portage/repos.conf"
cp "${rootfs_mount_path}/usr/share/portage/config/repos.conf" "${rootfs_mount_path}/etc/portage/repos.conf/gentoo.conf"

cp --dereference "/etc/resolv.conf" "${rootfs_mount_path}/etc/"

mount --types proc /proc "${rootfs_mount_path}/proc"
mount --rbind /sys "${rootfs_mount_path}/sys"
mount --make-rslave "${rootfs_mount_path}/sys"
mount --rbind /dev/ "${rootfs_mount_path}/dev"
mount --make-rslave "${rootfs_mount_path}/dev"
mount --bind /run "${rootfs_mount_path}/run"
mount --make-slave "${rootfs_mount_path}/run"

cp setup_gentoo.sh "${rootfs_mount_path}/setup_gentoo.sh"
chmod u+x "${rootfs_mount_path}/setup_gentoo.sh"

chroot "${rootfs_mount_path}" /bin/bash
