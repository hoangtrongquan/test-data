#!/bin/bash
set -e

USERNAME="trongquan"
HOSTNAME="arch-hyperland"
LOCALE="vi_VN.UTF-8"
TIMEZONE="Asia/Ho_Chi_Minh"

echo "[1] Thiết lập timezone, locale..."
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "$HOSTNAME" > /etc/hostname
cat >> /etc/hosts <<EOF
127.0.0.1 localhost
::1       localhost
127.0.1.1 $HOSTNAME.localdomain $HOSTNAME
EOF

echo "[2] Cài GRUB bootloader..."
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo "[3] Enable mạng + tạo user..."
systemctl enable NetworkManager
useradd -mG wheel $USERNAME
echo "root:123456" | chpasswd
echo "$USERNAME:123456" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "[4] Bật multilib..."
sed -i '/\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
pacman -Sy

echo "[5] Cài công cụ cơ bản..."
pacman -S --noconfirm git base-devel nano zsh neofetch unzip curl wget

echo "[6] Cài Nvidia driver..."
pacman -S --noconfirm nvidia nvidia-utils nvidia-prime libva libva-nvidia-driver

echo "[7] Cài Hyprland + môi trường..."
pacman -S --noconfirm hyprland kitty thunar rofi waybar dunst polkit-gnome \
xdg-desktop-portal-hyprland wl-clipboard brightnessctl pavucontrol firefox

echo "[8] Cài font & icon..."
pacman -S --noconfirm ttf-jetbrains-mono ttf-font-awesome papirus-icon-theme

echo "[9] Cấu hình Hyprland cho user..."
runuser -l $USERNAME -c '
mkdir -p ~/.config/hypr
cp -r /etc/xdg/hypr/* ~/.config/hypr/
echo "if [[ -z \$DISPLAY ]] && [[ \$(tty) = /dev/tty1 ]]; then Hyprland; fi" >> ~/.bash_profile
'

echo "✅ Đã hoàn tất! Bạn có thể reboot ngay để sử dụng Hyprland."
