#!/bin/bash
set -e

# ⚠️ Thay đổi nếu cần
DISK="/dev/nvme0n1"
EFI_PART="${DISK}p1"
ROOT_PART="${DISK}p2"

echo "[1] Phân vùng đĩa..."
parted -s $DISK mklabel gpt
parted -s $DISK mkpart ESP fat32 1MiB 513MiB
parted -s $DISK set 1 esp on
parted -s $DISK mkpart primary ext4 513MiB 100%

echo "[2] Định dạng phân vùng..."
mkfs.fat -F32 $EFI_PART
mkfs.ext4 $ROOT_PART

echo "[3] Mount phân vùng..."
mount $ROOT_PART /mnt
mkdir -p /mnt/boot
mount $EFI_PART /mnt/boot

echo "[4] Cài hệ thống cơ bản..."
pacstrap -K /mnt base linux linux-firmware nano sudo networkmanager grub efibootmgr

echo "[5] Tạo fstab và chroot..."
genfstab -U /mnt >> /mnt/etc/fstab
cp part2-in-chroot.sh /mnt/root/
chmod +x /mnt/root/part2-in-chroot.sh

echo "➡️ Sẵn sàng! Gõ lệnh sau để vào chroot và tiếp tục:"
echo "arch-chroot /mnt && bash /root/part2-in-chroot.sh"
