#!/bin/bash
set -e
 
DISK="/dev/nvme0n1"
EFI="${DISK}p1"
ROOT="${DISK}p2"
 
echo "⚠️ WARNING: Sẽ xoá toàn bộ dữ liệu trên $DISK sau 5 giây..."
sleep 5
 
echo "[1] Xoá sạch dữ liệu, phân vùng, bootloader cũ..."
wipefs -af $DISK
dd if=/dev/zero of=$DISK bs=1M count=100 status=progress
parted -s $DISK mklabel gpt
 
echo "[2] Tạo phân vùng EFI + ROOT..."
parted -s $DISK mkpart ESP fat32 1MiB 513MiB
parted -s $DISK set 1 esp on
parted -s $DISK mkpart primary ext4 513MiB 100%
 
echo "[3] Định dạng các phân vùng..."
mkfs.fat -F32 $EFI
mkfs.ext4 $ROOT
 
echo "[4] Mount phân vùng..."
mount $ROOT /mnt
mkdir -p /mnt/boot
mount $EFI /mnt/boot
 
echo "[5] Cài base system + intel microcode..."
pacstrap -K /mnt base linux linux-firmware intel-ucode \
sudo networkmanager grub efibootmgr nano
 
echo "[6] Tạo fstab và chép script phần 2 vào chroot..."
genfstab -U /mnt >> /mnt/etc/fstab
cp part2-in-chroot.sh /mnt/root/
chmod +x /mnt/root/part2-in-chroot.sh
 
echo "✅ Hoàn tất phần 1!"
echo "➡️ Tiếp tục bằng lệnh:"
echo "arch-chroot /mnt && bash /root/part2-in-chroot.sh"