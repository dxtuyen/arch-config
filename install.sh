#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
#  arch-config — cài toàn bộ dotfiles lên Arch Linux
#
#      git clone <repo> ~/arch-config && cd ~/arch-config && ./install.sh
#
#  Tuỳ chọn:
#      --skip-packages   chỉ cài dotfiles, không đụng tới gói hệ thống
#      --uninstall       gỡ toàn bộ symlink dotfiles (giữ nguyên dữ liệu)
#
#  Script IDEMPOTENT: chạy lại nhiều lần không sao.
# ══════════════════════════════════════════════════════════════
set -euo pipefail

REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PKG_LIST="$REPO/packages/official.txt"

C_G=$'\033[32m' C_Y=$'\033[33m' C_R=$'\033[31m' C_D=$'\033[2m' C_B=$'\033[1m' C_0=$'\033[0m'
step() { printf '\n%s▸ %s%s\n' "$C_B$C_G" "$*" "$C_0"; }
info() { printf '  %s%s%s\n' "$C_D" "$*" "$C_0"; }
warn() { printf '  %s! %s%s\n' "$C_Y" "$*" "$C_0"; }
die()  { printf '\n%s✗ %s%s\n' "$C_R" "$*" "$C_0" >&2; exit 1; }

SKIP_PKGS=0
UNINSTALL=0
for arg in "$@"; do
  case "$arg" in
    --skip-packages) SKIP_PKGS=1 ;;
    --uninstall)     UNINSTALL=1 ;;
    -h|--help)       sed -n '3,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)               die "Tham số lạ: $arg  (thử --help)" ;;
  esac
done

# ── Chặn nhầm trên máy chưa cài Arch ───────────────────────
[ -f /etc/arch-release ] || die "Máy này không phải Arch Linux."

# ── Gỡ dotfiles ────────────────────────────────────────────
if [ "$UNINSTALL" -eq 1 ]; then
  step "Gỡ symlink dotfiles (không đụng tới dữ liệu)"
  stow -t "$HOME"         -d "$REPO" -R home  2>/dev/null || true
  stow -t "$HOME/.config" -d "$REPO" -R config 2>/dev/null || true
  sudo stow -t /etc -d "$REPO" -R etc 2>/dev/null || true
  sudo stow -t /usr -d "$REPO" -R usr 2>/dev/null || true
  info "Dữ liệu trong ~/Pictures, ~/Books, ~/.config/quick-lang KHÔNG bị đụng tới."
  exit 0
fi

printf '%s\n' "$C_B"
printf '  arch-config — dotfiles cho Arch + Sway\n'
printf '  %s%s%s\n' "$C_D" "$REPO" "$C_0"
printf '%s\n' "$C_0"

# ── 1. Gói hệ thống ────────────────────────────────────────
if [ "$SKIP_PKGS" -eq 1 ]; then
  step "Bỏ qua gói hệ thống (--skip-packages)"
else
  step "Cài gói hệ thống"
  if ! command -v stow >/dev/null; then
    info "Cài stow trước để chạy nốt phần còn lại…"
    sudo pacman -S --needed --noconfirm stow
  fi
  # pacman tự bỏ qua dòng trống và dòng bắt đầu bằng '#'
  sudo pacman -Syu --needed --noconfirm - < "$PKG_LIST"
fi

# ── 2. Dotfiles ────────────────────────────────────────────
step "Liên kết dotfiles (GNU Stow)"
# Stow tạo symlink TARGET/<đường-dẫn-trong-package>. Vì vậy package
# `config` phải stow vào ~/.config (KHÔNG phải ~), còn package `home`
# vào ~ — đó là lý do tách 2 lệnh thay vì gộp.
#
# --overwrite: file đã tồn tại do app tự tạo (ví dụ ~/.config/mako/config)
# được thay bằng symlink. Stow KHÔNG xoá file gốc — nó đổi tên thành
# <file>.stow-backup, nên chạy lại vẫn an toàn.
mkdir -p "$HOME/.config"
stow    -t "$HOME"        -d "$REPO" --overwrite home
stow    -t "$HOME/.config" -d "$REPO" --overwrite config
sudo stow -t /etc -d "$REPO" --overwrite etc
sudo stow -t /usr -d "$REPO" --overwrite usr
info "~/.gitconfig  ~/.bashrc  ~/.local/bin/*  ~/.config/*  /etc/*  /usr/local/bin/*"

# ⚠️ Stow tạo symlink nhưng KHÔNG giữ quyền của file trong repo. Nên
# /etc/sudoers.d/wheel sẽ ra 644, và sudo SỎ IM LẶNG BỎ QUA file quyền
# sai — mất sudo mà không có một dòng cảnh báo nào. Sửa ngay tại đây.
if [ -e /etc/sudoers.d/wheel ]; then
  sudo chmod 440 /etc/sudoers.d/wheel
  if sudo visudo -c -f /etc/sudoers.d/wheel >/dev/null 2>&1; then
    info "sudoers.d/wheel: ok (440)"
  else
    warn "sudoers.d/wheel SAI CÚ PHÁP — bạn có thể mất quyền sudo. Kiểm tra:"
    warn "  sudo visudo -c -f /etc/sudoers.d/wheel"
  fi
fi

# ── 3. Thư mục dữ liệu người dùng ──────────────────────────
step "Tạo thư mục dữ liệu"
mkdir -p "$HOME/Pictures/wallpapers" "$HOME/Pictures/Screenshots" "$HOME/Books"
mkdir -p "$HOME/.config/quick-lang"
chmod 700 "$HOME/.config/quick-lang"
info "~/Pictures/{wallpapers,Screenshots}  ~/Books  ~/.config/quick-lang (đặt api.key ở đây)"

# ── 4. Plugin yazi ──────────────────────────────────────────
# smart-enter: <Enter> rẽ nhánh — thư mục thì đi vào, file thì mở app.
# Không có nó, preset của yazi mở nvim khi bấm <Enter> vào THƯ MỤC.
step "Cài plugin yazi (smart-enter)"
YAZI_PLUGIN="$HOME/.config/yazi/plugins/smart-enter.yazi"
if [ -d "$YAZI_PLUGIN" ]; then
  info "Đã có, giữ nguyên."
else
  command -v git >/dev/null || sudo pacman -S --needed --noconfirm git
  # ~/.config/yazi là symlink về repo → clone rơi thẳng vào repo, đúng ý đồ.
  git clone --depth 1 https://github.com/yazi-extensions/smart-enter "$YAZI_PLUGIN" \
    && info "OK" || warn "Không clone được (mạng?) — bỏ qua, yazi vẫn chạy."
fi


# ── 5. Ứng dụng AppImage ───────────────────────────────────
# ⛔ KHÔNG sinh file .desktop cho RemNote ở đây. File .desktop của
#    RemNote nằm BÊN TRONG AppImage, do tác giả app viết (đúng Exec, Icon,
#    Categories, MimeType). Viết tay thì dễ sai và lệch mỗi lần app cập
#    nhật — script `setup-remnote` sẽ lấy file gốc đó ra.
#
#    Trước khi bạn tải AppImage thì launcher không có RemNote. Đúng như
#    mong đợi, không phải lỗi.

# ── 6. Locale ──────────────────────────────────────────────
step "Sinh locale"
if ! locale -a 2>/dev/null | grep -qix 'en_US.utf8'; then
  sudo sed -i 's/^#\(en_US.UTF-8\)/\1/' /etc/locale.gen
  sudo locale-gen >/dev/null && info "en_US.UTF-8"
else
  info "đã có"
fi

# ── 7. Dịch vụ hệ thống ────────────────────────────────────
step "Bật dịch vụ hệ thống"
for svc in earlyoom keyd greetd fwupd; do
  sudo systemctl enable --now "$svc" 2>/dev/null && info "$svc" || warn "$svc: bật không được"
done
sudo systemctl enable --now fstrim.timer 2>/dev/null && info "fstrim.timer"

# earlyoom làm cơ chế OOM chính → tắt systemd-oomd cho khỏi chạy hai daemon.
sudo systemctl mask systemd-oomd.service >/dev/null 2>&1 && info "mask systemd-oomd"

# Ngưỡng sạc pin 85–90% (chống sạc 100% liên tục).
sudo systemctl enable battery-threshold.service 2>/dev/null \
  && info "battery-threshold.service" \
  || warn "battery-threshold: chưa thấy /usr/local/bin/set-battery-threshold"

# ── 8. Dịch vụ người dùng ──────────────────────────────────
step "Bật dịch vụ người dùng"
systemctl --user daemon-reload

# swayidle / awww-daemon / wallpaper-init / fcitx5 gắn vào
# sway-session.target nên tự chạy khi Sway khởi động — không cần enable
# thủ công. trash-clean.timer thì phải enable: nó chạy lúc 3h sáng,
# ngoài phiên Sway.
systemctl --user enable --now trash-clean.timer 2>/dev/null \
  && info "trash-clean.timer" || warn "trash-clean.timer: bật không được"

# wallpaper-init chạy SAU awww-daemon (After= trong unit) nên không cần
# bật thủ công ở đây, nhưng enable để chắc chắn nó được kéo lên cùng
# sway-session.target.
systemctl --user enable wallpaper-init.service 2>/dev/null \
  && info "wallpaper-init.service" || warn "wallpaper-init.service: bật không được"

# Timer phải chạy cả khi đã logout (máy ngủ). Bật linger cho user.
loginctl enable-linger "$USER" 2>/dev/null && info "linger: bật" || true

# ── 9. Kiểm tra ────────────────────────────────────────────
step "Kiểm tra"
miss=0
for c in sway swaymsg swaylock swayidle waybar foot mako rofi wlsunset awww fcitx5 \
         keyd powerprofilesctl wpctl brightnessctl jq yazi imv mpv; do
  command -v "$c" >/dev/null || { warn "thiếu: $c"; miss=1; }
done

if [ ! -f /usr/lib/systemd/user/sway-session.target ]; then
  warn "Không thấy sway-session.target — service gắn vào target này sẽ không chạy."
  warn "Kiểm tra lại gói 'sway' đã được cài đúng chưa."
fi

# ── 10. Git identity ────────────────────────────────────────
step "Git identity"
if git config --global user.email >/dev/null 2>&1; then
  info "đã có: $(git config --global user.email)"
elif [ -n "${GIT_USER_NAME:-}" ] && [ -n "${GIT_USER_EMAIL:-}" ]; then
  git config --global user.name  "$GIT_USER_NAME"
  git config --global user.email "$GIT_USER_EMAIL"
  info "đặt từ biến môi trường"
else
  info "chưa có — đặt tay:"
  info "  git config --global user.name 'Tên'"
  info "  git config --global user.email 'a@b.c'"
fi

# ── 11. Gợi ý cuối ─────────────────────────────────────────
printf '\n%s✔ Xong.%s\n' "$C_G" "$C_0"
[ "$miss" -eq 1 ] && printf '%s  Còn thiếu gói ở trên — chạy lại ./install.sh khi có mạng.%s\n' "$C_Y" "$C_0"

cat <<'EOF'

  ── Bootstrap (làm MỘT LẦN, trước khi reboot lần đầu) ──

    # tạo user (thay <tên> và mật khẩu)
    useradd -m -G wheel -s /bin/bash <tên>
    passwd <tên>
    echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel
    chmod 440 /etc/sudoers.d/wheel
    visudo -c /etc/sudoers.d/wheel

    # cài dotfiles cho user đó
    su - <tên>
    git clone <repo> ~/arch-config && cd ~/arch-config && ./install.sh

  ── Bootloader systemd-boot (sau khi đã có user) ──

    sudo pacman -S --needed systemd efibootmgr linux linux-firmware
    sudo mkinitcpio -P
    sudo bootctl install
    sudo kernel-install add-all "$(uname -r)"

  Xem README.md mục "Cài máy mới" để có trọn các lệnh.

EOF
