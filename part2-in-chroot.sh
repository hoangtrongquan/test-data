#!/bin/bash
set -e

echo ">>> Setting timezone, locale..."
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
hwclock --systohc

echo ">>> Configuring locale..."
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf

echo ">>> Setting hostname..."
echo "arch-hyper" > /etc/hostname
cat >> /etc/hosts <<EOF
127.0.0.1 localhost
::1       localhost
127.0.1.1 arch-hyper.localdomain arch-hyper
EOF

echo ">>> Installing essential packages..."
pacman -Sy --noconfirm grub efibootmgr networkmanager network-manager-applet base-devel linux-headers reflector bluez bluez-utils cups openssh avahi xdg-user-dirs xdg-utils unzip p7zip lsb-release

echo ">>> Enabling services..."
systemctl enable NetworkManager bluetooth sshd cups avahi-daemon

echo ">>> Installing microcode and bootloader..."
pacman -S --noconfirm intel-ucode
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo ">>> Creating user and setting password..."
useradd -mG wheel,audio,video,storage,optical,lp,input yourname
echo "Set password for root:"
passwd
echo "Set password for yourname:"
passwd yourname

echo ">>> Allowing wheel sudo..."
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo ">>> Installing Hyprland and GUI stack..."
pacman -S --noconfirm hyprland xdg-desktop-portal-hyprland kitty waybar dmenu dolphin thunar thunar-volman xwayland qt5-wayland qt6-wayland

echo ">>> Installing Display Manager (SDDM)..."
pacman -S --noconfirm sddm sddm-kcm qt5-quickcontrols qt5-graphicaleffects
systemctl enable sddm

echo ">>> Installing SDDM theme..."
git clone https://github.com/vinceliuice/Sweet.git /tmp/sddm-theme
cp -r /tmp/sddm-theme/SDDM/Sugar-Light /usr/share/sddm/themes/
sed -i 's/^Current=.*/Current=Sugar-Light/' /etc/sddm.conf

echo ">>> Installing ZSH + Powerlevel10k..."
pacman -S --noconfirm zsh zsh-autosuggestions zsh-syntax-highlighting
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /usr/share/zsh-theme-powerlevel10k
echo 'source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme' >> /etc/zsh/zshrc
chsh -s /bin/zsh yourname

echo ">>> Installing PipeWire & Volume controls..."
pacman -S --noconfirm pipewire pipewire-pulse wireplumber pavucontrol
systemctl enable --user pipewire wireplumber

echo ">>> Installing Chrome, IntelliJ, VSCode via flatpak..."
pacman -S --noconfirm flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.google.Chrome com.jetbrains.IntelliJ-IDEA-Ultimate com.visualstudio.code

echo ">>> Installing Vietnamese Input (IBus Bamboo)..."
pacman -S --noconfirm ibus ibus-bamboo
echo 'export GTK_IM_MODULE=ibus' >> /etc/environment
echo 'export QT_IM_MODULE=ibus' >> /etc/environment
echo 'export XMODIFIERS=@im=ibus' >> /etc/environment
systemctl enable --user ibus

echo ">>> Copying Hyprland config..."
mkdir -p /home/yourname/.config/hypr
cp -r /etc/skel/.config/hypr/* /home/yourname/.config/hypr/
chown -R yourname:yourname /home/yourname/.config

echo ">>> Setup auto-login for SDDM..."
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/autologin.conf <<EOF
[Autologin]
User=yourname
Session=hyprland
EOF

echo ">>> Done! You can now reboot."
