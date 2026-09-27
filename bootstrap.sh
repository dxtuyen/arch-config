#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
#  bootstrap.sh — cài Arch Linux trên máy thật, 1 lệnh
#
#  Chạy trong live shell (đã boot từ USB, đã vào mạng):
#      git clone https://github.com/dxtuyen/arch-config.git
#      sudo arch-config/bootstrap.sh
# ══════════════════════════════════════════════════════════════

set -euo pipefail

REPO="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
TARGET="${TARGET:-/mnt}"
HOSTNAME="archbook"
USER_NAME="doxuantuyen"
USER_PASS="63795664"
TIMEZONE="Asia/Ho_Chi_Minh"
LOCALE="en_US.UTF-8"

# ── Hiển thị ────────────────────────────────────────────────────
if [ -t 1 ]; then C_R=$'\033[0m'; C_B=$'\033[1m'; C_G=$'\033[32m'
                C_Y=$'\033[33m'; C_X=$'\033[31m'; C_D=$'\033[2m'
else C_R=; C_B=; C_G=; C_Y=; C_X=; C_D=; fi
step() { printf '%s\n' "${C_B}▸ $*${C_R}"; }
ok()   { printf '  %s✓%s %s\n' "$C_G" "$C_R" "$*"; }
warn() { printf '  %s!%s %s\n' "$C_Y" "$C_R" "$*"; }
die()  { printf '\n%s✗ %s%s\n' "$C_X" "$*" "$C_R" >&2; exit 1; }

printf '%s\n\n' "${C_B}  arch-config · bootstrap${C_R}"
printf '%s\n\n' "${C_D}  Cài Arch + dotfiles, đúng thứ tự để boot được${C_R}"

# ══ 1. Điều kiện tiên quyết ═══════════════════════════════════
[[ -d /run/archiso ]] || die "Chạy trong live shell Arch, KHÔNG phải hệ thống đã cài.
  Nếu đã cài rồi thì chỉ cần:  cd ~/arch-config && ./install.sh"
[[ $EUID -eq 0 ]] || die "Cần root:  sudo arch-config/bootstrap.sh"
command -v pacstrap >/dev/null || die "Thiếu pacstrap — chắc chắn không ở live ISO."
[[ -d $REPO ]] || die "Không thấy repo ở $REPO"

# ══ 2. Kiểm tra phân vùng (KHÔNG tự phân vùng) ════════════════
step "Kiểm tra phân vùng"

if ! mountpoint -q "$TARGET"; then
  cat >&2 <<EOF

${C_X}Chưa mount $TARGET. Phân vùng là phần DUY NHẤT script không tự làm,${C_R}
${C_D}vì xoá nhầm thì mất sạch ổ cứng và không có cách gỡ.${C_R}

  cfdisk /dev/nvme0n1
    • 1 GiB   →  EFI System        (phân vùng 1)
    • còn lại →  Linux filesystem  (phân vùng 2)

  mkfs.fat -F32 /dev/nvme0n1p1
  mkfs.ext4   /dev/nvme0n1p2
  mount      /dev/nvme0n1p2 $TARGET
  mount --mkdir /dev/nvme0n1p1 $TARGET/boot

${C_Y}Xong đó chạy lại script này.${C_R}

EOF
  exit 1
fi

esp_dev="$(findmnt -n -o SOURCE "$TARGET/boot" 2>/dev/null || true)"
[[ -n $esp_dev ]] || die "$TARGET/boot chưa mount. ESP phải mount ở đây,
  nếu không bootctl sẽ cài sai chỗ. Chạy:
    mount --mkdir /dev/nvme0n1p1 $TARGET/boot"

root_dev="$(findmnt -n -o SOURCE "$TARGET")"
root_uuid="$(blkid -s UUID -o value "$root_dev")"
esp_uuid="$(blkid -s UUID -o value "$esp_dev")"
[[ -n $root_uuid && -n $esp_uuid ]] || die "Không đọc được UUID — kiểm tra phân vùng."

ok "root  $root_dev  UUID=$root_uuid"
ok "boot  $esp_dev  UUID=$esp_uuid"

printf '\n%s  CÀI ĐÈ lên %s — mất toàn bộ NixOS trên /dev/nvme0n1.%s\n' \
  "$C_Y" "$root_dev" "$C_R"
printf '%s  Đã backup key Gemini + ảnh nền chưa?%s\n' "$C_Y" "$C_R"
printf '  Gõ "phai" để bắt đầu, Ctrl+C để dừng: '
read -r reply
[[ $reply == "phai" ]] || die "Đã dừng. Không thay đổi gì cả."

# ══ 3. pacstrap ═══════════════════════════════════════════════
step "Cài gói nền (pacstrap)"

pacstrap -K "$TARGET" \
  base linux linux-firmware systemd mkinitcpio \
  sudo git efibootmgr intel-ucode
ok "base + linux + sudo + git + efibootmgr + intel-ucode"

# ══ 4. Cấu hình trong chroot ═══════════════════════════════════
step "Cấu hình hệ thống trong chroot"

arch-chroot "$TARGET" /bin/bash -euo pipefail <<CHROOT
export DEBIAN_FRONTEND=noninteractive

pacman-key --init
pacman-key --populate archlinux

if [ ! -f /etc/pacman.d/mirrorlist ] || [ ! -s /etc/pacman.d/mirrorlist ]; then
  echo 'Server = https://geo.mirror.pkgbuild.com/\$repo/os/\$arch' > /etc/pacman.d/mirrorlist
fi
pacman -Sy --needed --noconfirm

ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

sed -i 's/^#\($LOCALE\)/\1/' /etc/locale.gen
locale-gen
printf 'LANG=%s\n' '$LOCALE' > /etc/locale.conf
printf 'KEYMAP=us\n' > /etc/vconsole.conf
printf '%s\n' '$HOSTNAME' > /etc/hostname

{
  printf 'UUID=%s / ext4 defaults,noatime 0 1\n' '$root_uuid'
  printf 'UUID=%s /boot vfat defaults,fmask=0077,dmask=0077 0 2\n' '$esp_uuid'
} > /etc/fstab

id '$USER_NAME' &>/dev/null || useradd -m -G wheel -s /bin/bash '$USER_NAME'
printf '%s:%s\n' '$USER_NAME' '$USER_PASS' | chpasswd
printf 'root:%s\n' '$USER_PASS' | chpasswd
printf '%%wheel ALL=(ALL:ALL) ALL\n' > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel
visudo -c -f /etc/sudoers.d/wheel

pacman -S --needed --noconfirm networkmanager iwd
systemctl enable NetworkManager.service
mkdir -p /etc/NetworkManager
cat > /etc/NetworkManager/NetworkManager.conf <<'NMCONF'
[main]
dns=systemd-resolved
wifi.backend=iwd
[connection]
wifi.cloned-mac-address=stable
NMCONF
systemctl enable systemd-resolved.service

ln -sfn /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf 2>/dev/null || true
CHROOT
ok "múi giờ · locale · fstab · user · NetworkManager + iwd"

# ══ 5. Cài dotfiles ════════════════════════════════════════════
step "Cài dotfiles (git clone + install.sh)"

arch-chroot "$TARGET" /bin/bash -euo pipefail <<'INNER'
rm -rf /root/arch-config
git clone https://github.com/dxtuyen/arch-config.git /root/arch-config
cd /root/arch-config
chmod +x install.sh bootstrap.sh
./install.sh
INNER
ok "dotfiles đã cài"
warn "Nhớ copy API key Gemini sang máy mới:"
warn "  cp <file> ~/.config/quick-lang/ && chmod 600 ~/.config/quick-lang/api.key"

# ══ 6. initramfs rồi mới bootloader ════════════════════════════
step "Tạo initramfs và cấu hình bootloader"

arch-chroot "$TARGET" /bin/bash -euo pipefail <<BOOT
mkinitcpio -P
bootctl install

# Tự tạo cấu hình loader chung
cat > /boot/loader/loader.conf << 'LOADER'
default arch.conf
timeout 3
console-mode max
editor no
LOADER

# Tự tạo file entry boot cho Arch Linux bằng UUID chuẩn
mkdir -p /boot/loader/entries
cat > /boot/loader/entries/arch.conf << ENTRY
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=UUID=$root_uuid rw quiet mem_sleep_default=deep
ENTRY

echo "--- bootctl list ---"
bootctl list
BOOT

# ══ 7. Xác nhận bootloader có thật ═════════════════════════════
step "Kiểm tra bootloader"
if arch-chroot "$TARGET" bootctl list 2>/dev/null | grep -qE 'title:.*Arch Linux'; then
  ok "bootctl đã nhận cấu hình Arch Linux — máy chắc chắn boot được"
else
  die "bootctl list vẫn không nhận entry. Kiểm tra lại /boot/loader/entries/"
fi

# ══ 8. Bàn giao ═══════════════════════════════════════════════
printf '\n'
printf '%s%s  XONG — có thể reboot%s\n\n' "$C_G" "$C_B" "$C_R"
cat <<EOF
  ${C_B}Sau khi reboot${C_R}
    1. greetd/tuigreet hiện ra → nhập tên: $USER_NAME
    2. Mật khẩu: $USER_PASS
    3. Sway tự lên.

  ${C_B}Kiểm tra ngay${C_R} (cả hai phải TRỐNG)
    systemctl --failed
    systemctl --user --failed
    systemctl --user list-timers | grep trash
    free -h | grep zram0
EOF
printf '  %sRút USB rồi mới reboot.%s\n\n' "$C_Y" "$C_R"
