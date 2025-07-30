#!/bin/bash
# File: setup.sh — chạy từ USB trước khi chroot

set -e
DISK="/dev/nvme0n1"      # Nếu là nvme khác, hãy điều chỉnh lại
HOSTNAME="arch-hypr"
USERNAME="trongquan"
PASSWORD="123456"
LOCALE="en_US.UTF-8"

# Phân vùng
sgdisk -Z $DISK
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:"EFI" $DISK
sgdisk -n 2:0:0     -t 2:8300 -c 2:"LinuxRoot" $DISK

# Format & mount
mkfs.fat -F32 "${DISK}p1"
mkfs.ext4 "${DISK}p2"
mount "${DISK}p2" /mnt
mkdir -p /mnt/boot/efi
mount "${DISK}p1" /mnt/boot/efi

# Cài base system
pacstrap -K /mnt base base-devel linux linux-firmware linux-headers \
  networkmanager vim sudo git intel-ucode

# Tạo fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Copy script chroot vào /root
cp chroot.sh /mnt/root/chroot.sh
chmod +x /mnt/root/chroot.sh

# Chroot và chạy
arch-chroot /mnt /root/chroot.sh