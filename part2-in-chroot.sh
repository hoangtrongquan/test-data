#!/bin/bash
set -e
 
echo "[1] Cấu hình múi giờ, ngôn ngữ..."
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
hwclock --systohc
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
 
echo "arch" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1 localhost
::1       localhost
127.0.1.1 arch.localdomain arch
EOF
 
echo "[2] Cài GRUB + Theme Vimix"
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
pacman -S --noconfirm git
git clone --depth=1 https://github.com/vinceliuice/grub2-themes /opt/grub2-themes
bash /opt/grub2-themes/install.sh -b -t vimix -s 1080p
 
echo "[3] Đặt mật khẩu root..."
echo "root:hoangquan" | chpasswd
 
echo "[4] Bật dịch vụ khởi động..."
systemctl enable NetworkManager
systemctl enable sddm
 
echo "[5] Cài Hyperland, PipeWire, font và app cần thiết..."
pacman -S --noconfirm --needed \
xorg xdg-desktop-portal-hyprland hyprland \
mesa libva libvdpau \
pipewire wireplumber pamixer \
sddm qt5-wayland qt6-wayland \
kitty waybar rofi thunar \
neovim zsh wget curl unzip \
ttf-font-awesome ttf-jetbrains-mono noto-fonts noto-fonts-cjk noto-fonts-emoji \
firefox grim slurp wl-clipboard brightnessctl
 
echo "[6] Tạo user hoangquan..."
useradd -mG wheel,input,audio,video -s /bin/zsh hoangquan
echo "hoangquan:123456" | chpasswd
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
 
echo "[7] Thêm theme SDDM (Catppuccin)..."
git clone --depth=1 https://github.com/catppuccin/sddm.git /usr/share/sddm/themes/catppuccin
mkdir -p /etc/sddm.conf.d
echo -e "[Theme]\nCurrent=catppuccin" > /etc/sddm.conf.d/theme.conf
 
echo "[8] Powerlevel10k ZSH theme cho hoangquan..."
sudo -u hoangquan bash <<'EOF'
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.p10k
echo 'source ~/.p10k/powerlevel10k.zsh-theme' >> ~/.zshrc
EOF
 
echo "[9] Tạo config Hyprland mặc định với blur + shadow + volume key..."
sudo -u hoangquan bash <<'EOF'
mkdir -p ~/.config/hypr
cat > ~/.config/hypr/hyprland.conf <<CONFIG
exec-once = waybar &
exec-once = nm-applet &
 
monitor = ,preferred,auto,1
 
input {
  kb_layout = us
  follow_mouse = 1
  touchpad {
    natural_scroll = yes
  }
}
 
general {
  gaps_in = 5
  gaps_out = 10
  border_size = 2
  col.active_border = rgba(33ccffee)
  col.inactive_border = rgba(595959aa)
}
 
decoration {
  rounding = 10
  blur {
    enabled = true
    size = 8
    passes = 3
    new_optimizations = on
  }
  drop_shadow = yes
  shadow_range = 20
  shadow_render_power = 3
  col.shadow = rgba(000000aa)
}
 
animations {
  enabled = yes
  bezier = ease, 0.25, 0.1, 0.25, 1
  animation = windows, 1, 3, ease, slide
  animation = fade, 1, 3, ease
}
 
bind = SUPER, RETURN, exec, kitty
bind = SUPER, D, exec, rofi -show drun
bind = SUPER, Q, killactive,
bind = SUPER, E, exec, thunar
bind = SUPER, V, togglefloating,
bind = SUPER, F, fullscreen,
 
# Volume
bind = , XF86AudioRaiseVolume, exec, pamixer -i 5
bind = , XF86AudioLowerVolume, exec, pamixer -d 5
bind = , XF86AudioMute, exec, pamixer -t
CONFIG
EOF
 
echo "✅ Hoàn tất! Giờ bạn có Hyprland + blur + shadow + âm lượng hoạt động."
echo "➡️ Exit rồi chạy: umount -R /mnt && reboot"