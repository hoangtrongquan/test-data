#!/bin/bash
# File: chroot.sh — chạy bên trong arch-chroot

set -e
DISK="/dev/nvme0n1"
USERNAME="trongquan"
PASSWORD="123456"

# Timezone & locale
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Hostname & hosts
echo "arch-hypr" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   arch-hypr.localdomain arch-hypr
EOF

# User & sudo
useradd -mG wheel,docker $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
echo "root:$PASSWORD" | chpasswd
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel

# Bootloader systemd-boot
bootctl install
PARTUUID=$(blkid -s PARTUUID -o value "${DISK}p2")
cat <<EOF > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=PARTUUID=$PARTUUID rw
EOF
cat <<EOF > /boot/loader/loader.conf
default arch
timeout 3
console-mode max
editor no
EOF

# Enable NetworkManager
systemctl enable NetworkManager

# Cài Hyprland & GUI cơ bản
pacman -Sy --noconfirm xorg wayland wayland-protocols \
  hyprland kitty thunar firefox \
  ttf-font-awesome ttf-dejavu ttf-jetbrains-mono \
  pipewire wireplumber xdg-desktop-portal-hyprland \
  grim slurp wl-clipboard swaybg brightnessctl \
  polkit-kde-agent mako rofi

# Auto‑login TTY1
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat <<EOF > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USERNAME --noclear %I \$TERM
EOF

# Tự khởi Hyprland khi login
echo 'exec Hyprland' > /home/$USERNAME/.bash_profile
chown $USERNAME:$USERNAME /home/$USERNAME/.bash_profile

# Cài Docker & enable
pacman -S --noconfirm docker
systemctl enable docker
usermod -aG docker $USERNAME

echo "=== Hoàn thành trong chroot. Quay ra khỏi chroot, unmount & reboot để khởi động hệ thống ==="