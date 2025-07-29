#!/bin/bash
set -e
 
echo "[1] Đặt múi giờ, locale, hostname..."
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
hwclock --systohc
 
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "hoang-pc" > /etc/hostname
 
echo "[2] Cài user..."
useradd -m -G wheel,audio,video,network hoang
echo "Đặt mật khẩu cho user hoang:"
passwd hoang
echo "Đặt mật khẩu root:"
passwd
 
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
 
echo "[3] Cài GRUB + theme đẹp..."
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
pacman -S --noconfirm grub-theme-vimix
mkdir -p /boot/grub/themes
cp -r /usr/share/grub/themes/Vimix /boot/grub/themes/
echo 'GRUB_THEME="/boot/grub/themes/Vimix/theme.txt"' >> /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
 
echo "[4] Cài đồ họa: Hyprland, drivers, Wayland tools..."
pacman -S --noconfirm hyprland xdg-desktop-portal-hyprland \
mesa vulkan-intel libva-intel-driver libva-utils \
nvidia nvidia-utils nvidia-settings nvidia-dkms \
waybar rofi alacritty kitty dolphin neofetch \
ttf-jetbrains-mono ttf-firacode-nerd ttf-font-awesome \
sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg qt5-quickcontrols \
qt6-wayland qt6-svg qt6-quickcontrols2 qt6-graphicaleffects \
zsh zsh-autosuggestions zsh-syntax-highlighting \
pipewire wireplumber pamixer pavucontrol \
grim slurp wl-clipboard brightnessctl \
network-manager-applet blueman
 
echo "[5] Cài theme SDDM..."
git clone --depth=1 https://github.com/vinceliuice/SDDM-Catppuccin.git /tmp/sddm-theme
/tmp/sddm-theme/install.sh --theme mocha
mkdir -p /etc/sddm.conf.d
echo -e "[Theme]\nCurrent=catppuccin-mocha" > /etc/sddm.conf.d/theme.conf
 
echo "[6] Bật dịch vụ..."
systemctl enable NetworkManager
systemctl enable sddm
 
echo "[7] Auto login SDDM vào user hoang và Hyprland..."
echo -e "[Autologin]\nUser=hoang\nSession=hyprland" > /etc/sddm.conf.d/autologin.conf
 
echo "[8] Cài Powerlevel10k..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/hoang/.p10k
echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> /home/hoang/.zshrc
echo 'source ~/.p10k/powerlevel10k.zsh-theme' >> /home/hoang/.zshrc
echo 'source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh' >> /home/hoang/.zshrc
echo 'source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh' >> /home/hoang/.zshrc
chsh -s /bin/zsh hoang
chown -R hoang:hoang /home/hoang
 
echo "[9] Tạo config Hyprland..."
mkdir -p /home/hoang/.config/hypr
cat <<EOF > /home/hoang/.config/hypr/hyprland.conf
exec-once = waybar & blueman-applet & nm-applet & pavucontrol & dolphin & alacritty
 
monitor=,preferred,auto,1
 
input {
    kb_layout = us
    follow_mouse = 1
}
 
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}
 
decoration {
    rounding = 10
    blur {
        enabled = true
        size = 5
        passes = 3
    }
    drop_shadow = true
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(00000044)
}
 
animations {
    enabled = true
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}
 
bind = $mainMod, RETURN, exec, alacritty
bind = $mainMod, Q, killactive
bind = $mainMod, E, exec, dolphin
bind = $mainMod, V, togglefloating
bind = $mainMod, SPACE, exec, rofi -show drun
 
bind = , XF86AudioRaiseVolume, exec, pamixer -i 5
bind = , XF86AudioLowerVolume, exec, pamixer -d 5
bind = , XF86AudioMute, exec, pamixer -t
EOF
 
chown -R hoang:hoang /home/hoang/.config
 
echo "✅ DONE! Giờ bạn có thể thoát chroot và reboot!"