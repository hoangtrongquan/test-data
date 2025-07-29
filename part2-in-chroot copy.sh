#!/bin/bash
set -e
 
USERNAME=hoang
HOSTNAME=archlinux
 
echo "[1] Cài đặt timezone, locale, hostname..."
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "$HOSTNAME" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts
 
echo "[2] Tạo user và set password..."
useradd -m -G wheel,audio,video,network,users -s /bin/zsh $USERNAME
echo "$USERNAME:123" | chpasswd
echo "root:123" | chpasswd
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
 
echo "[3] Cài SDDM và cấu hình auto login..."
pacman -S --noconfirm sddm
systemctl enable sddm
mkdir -p /etc/sddm.conf.d
echo -e "[Autologin]\nUser=$USERNAME\nSession=hyprland" > /etc/sddm.conf.d/autologin.conf
 
echo "[4] Cài driver, PipeWire, zsh, git..."
pacman -S --noconfirm mesa nvidia nvidia-utils \
pipewire wireplumber pipewire-audio pipewire-pulse pamixer \
zsh zsh-autosuggestions zsh-syntax-highlighting git unzip
 
echo "[5] Cài Hyprland và tiện ích liên quan..."
pacman -S --noconfirm hyprland xdg-desktop-portal-hyprland \
waybar rofi kitty thunar thunar-archive-plugin file-roller \
ttf-jetbrains-mono ttf-nerd-fonts-symbols ttf-fira-code noto-fonts noto-fonts-cjk
 
echo "[6] Tạo cấu hình Hyprland cho $USERNAME..."
su - $USERNAME -c "git clone https://github.com/hyprwm/Hyprland ~/.config/hypr && cp -r ~/.config/hypr/example ~/.config/hypr"
su - $USERNAME -c "mkdir -p ~/.config/waybar && echo '{}' > ~/.config/waybar/config.jsonc"
 
echo "[7] Cài trình duyệt và công cụ dev..."
pacman -S --noconfirm google-chrome docker docker-compose \
visual-studio-code-bin intellij-idea-ultimate-edition
 
systemctl enable docker
usermod -aG docker $USERNAME
 
echo "[8] Cài n8n local qua npm..."
pacman -S --noconfirm nodejs npm
su - $USERNAME -c "npm install -g n8n"
 
echo "[9] Thêm theme zsh powerlevel10k..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/$USERNAME/.p10k
echo 'source ~/.p10k/powerlevel10k.zsh-theme' >> /home/$USERNAME/.zshrc
chown -R $USERNAME:$USERNAME /home/$USERNAME
 
echo "[10] Thêm theme GRUB đẹp (catppuccin)..."
git clone https://github.com/catppuccin/grub.git /boot/grub/themes/catppuccin
echo 'GRUB_THEME="/boot/grub/themes/catppuccin/src/catppuccin-mocha-grub-theme/theme.txt"' >> /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
 
echo "✅ Hoàn tất cài đặt! Reboot để trải nghiệm."