#!/bin/sh

rootfs_part_name="sda3"
rootfs_mount_path="/mnt/gentoo"

mkdir -p "${rootfs_mount_path}"
mount "/dev/${rootfs_part_name}" "${rootfs_mount_path}"

cp --dereference "/etc/resolv.conf" "${rootfs_mount_path}/etc/"

mount --types proc /proc "${rootfs_mount_path}/proc"
mount --rbind /sys "${rootfs_mount_path}/sys"
mount --make-rslave "${rootfs_mount_path}/sys"
mount --rbind /dev/ "${rootfs_mount_path}/dev"
mount --make-rslave "${rootfs_mount_path}/dev"
mount --bind /run "${rootfs_mount_path}/run"
mount --make-slave "${rootfs_mount_path}/run"

chroot "${rootfs_mount_path}" /bin/bash
