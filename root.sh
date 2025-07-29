#!/bin/bash
 
# =======================
# ARCH + HYPERLAND FULL SETUP SCRIPT
# Target: Acer Nitro 5 (Intel Gen 11, No NVIDIA)
# Purpose: Coding (IntelliJ, VSCode), Docker, Chrome, No Gaming
# =======================
 
set -e
 
# -----------------------
# 1. WIPE AND PREPARE DISK (Assuming /dev/nvme0n1)
# -----------------------
echo "[1] Wiping and partitioning disk..."
sgdisk -Z /dev/nvme0n1
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:EFI /dev/nvme0n1
sgdisk -n 2:0:0     -t 2:8300 -c 2:ROOT /dev/nvme0n1
 
mkfs.fat -F32 /dev/nvme0n1p1
mkfs.btrfs -f /dev/nvme0n1p2
 
mount /dev/nvme0n1p2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt
 
mount -o noatime,compress=zstd,subvol=@ /dev/nvme0n1p2 /mnt
mkdir -p /mnt/{boot/efi,home}
mount -o noatime,compress=zstd,subvol=@home /dev/nvme0n1p2 /mnt/home
mount /dev/nvme0n1p1 /mnt/boot/efi
 
# -----------------------
# 2. INSTALL BASE SYSTEM
# -----------------------
echo "[2] Installing base system..."
pacstrap /mnt base base-devel linux linux-firmware linux-headers btrfs-progs intel-ucode sudo nano networkmanager grub efibootmgr
 
# -----------------------
# 3. FSTAB & CHROOT
# -----------------------
genfstab -U /mnt >> /mnt/etc/fstab
 
cp $0 /mnt/root/arch-setup.sh
arch-chroot /mnt /root/arch-setup.sh --in-chroot
exit
 
# =======================
# --- INSIDE CHROOT ---
# =======================
 
if [[ "$1" == "--in-chroot" ]]; then
  echo "[3] Inside chroot..."
  
  ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
  hwclock --systohc
 
  echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
  locale-gen
  echo "LANG=en_US.UTF-8" > /etc/locale.conf
  echo "archlinux" > /etc/hostname
  echo -e "127.0.0.1\tlocalhost\n::1\tlocalhost\n127.0.1.1\tarchlinux.localdomain\tarchlinux" >> /etc/hosts
 
  useradd -mG wheel,trusted,uucp,storage,optical,audio,video,input,lp,sys,network docker -s /bin/zsh
  echo "docker:123" | chpasswd
  echo "root:123" | chpasswd
 
  sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
 
  systemctl enable NetworkManager
 
  echo "[3.1] Installing bootloader..."
  grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
  grub-mkconfig -o /boot/grub/grub.cfg
 
  echo "[3.2] Enabling auto-login to user docker..."
  mkdir -p /etc/systemd/system/getty@tty1.service.d
  cat <<EOF > /etc/systemd/system/getty@tty1.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin docker --noclear %I \$TERM
EOF
 
  echo "[4] Installing GUI and tools..."
  pacman -S --noconfirm hyprland waybar rofi dunst kitty thunar pavucontrol brightnessctl wl-clipboard wofi xdg-desktop-portal-hyprland xdg-user-dirs grim slurp swaybg sddm sddm-kcm btop neofetch zsh powerlevel10k firefox
 
  echo "[4.1] Installing sound system (PipeWire)..."
  pacman -S --noconfirm pipewire pipewire-alsa pipewire-pulse wireplumber
 
  echo "[4.2] Enabling services..."
  systemctl enable sddm.service
 
  echo "[4.3] Setting up zsh and theme..."
  echo 'export ZSH="/usr/share/oh-my-zsh"' >> /etc/zsh/zshrc
  echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> /etc/zsh/zshrc
  echo 'plugins=(git)' >> /etc/zsh/zshrc
  echo 'source $ZSH/oh-my-zsh.sh' >> /etc/zsh/zshrc
 
  echo "[4.4] Installing fonts and appearance..."
  pacman -S --noconfirm ttf-fira-code ttf-font-awesome ttf-jetbrains-mono noto-fonts noto-fonts-cjk noto-fonts-emoji
 
  echo "[4.5] Installing Vietnamese input method (IBus + Bamboo)..."
  pacman -S --noconfirm ibus ibus-bamboo
  echo 'GTK_IM_MODULE=ibus' >> /etc/environment
  echo 'QT_IM_MODULE=ibus' >> /etc/environment
  echo 'XMODIFIERS=@im=ibus' >> /etc/environment
  systemctl --global enable ibus
 
  echo "[4.6] Setting up default Hyprland config for user docker..."
  mkdir -p /home/docker/.config/hypr
  cp -r /etc/skel/.config/hypr/* /home/docker/.config/hypr 2>/dev/null || true
  chown -R docker:docker /home/docker/.config
 
  echo "[5] Installing coding tools..."
  pacman -S --noconfirm docker code intellij-idea-ultimate
  systemctl enable docker
 
  echo "[5.1] Installing Google Chrome..."
  pacman -S --noconfirm google-chrome
 
  echo "[5.2] Recommended IntelliJ & VSCode plugins (install manually):"
  echo " - Rainbow Brackets"
  echo " - Material Theme UI"
  echo " - GitLens / GitToolBox"
  echo " - Docker / Kubernetes plugin"
  echo " - IntelliLang / String Manipulation"
 
  echo "[✔] Done. Type 'exit' and reboot."
  exit
fi
 