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
  
  # Lọc bỏ comment, dòng trống và lấy đúng tên package
  awk '{if ($1 && $1 !~ /^#/) print $1}' "$PKG_LIST" | sudo pacman -Syu --needed --noconfirm -
fi

# ── 2. Dotfiles ────────────────────────────────────────────
step "Liên kết dotfiles (GNU Stow)"
mkdir -p "$HOME/.config"
stow    -t "$HOME"        -d "$REPO" --adopt home
stow    -t "$HOME/.config" -d "$REPO" --adopt config
sudo stow -t /etc -d "$REPO" --adopt etc
sudo stow -t /usr -d "$REPO" --adopt usr
info "~/.gitconfig  ~/.bashrc  ~/.local/bin/*  ~/.config/*  /etc/*  /usr/local/bin/*"

if [ -e /etc/sudoers.d/wheel ]; then
  sudo chmod 440 /etc/sudoers.d/wheel
  if sudo visudo -c -f /etc/sudoers.d/wheel >/dev/null 2>&1; then
    info "sudoers.d/wheel: ok (440)"
  else
    warn "sudoers.d/wheel SAI CÚ PHÁP — bạn có thể mất quyền sudo. Kiểm tra:"
    warn "  sudo visudo -c -f /etc/sudoers.d/wheel"
  fi
fi

# ── 3. Sinh ~/.config/environment.d từ session-env.sh ───────
step "Sinh environment.d từ session-env.sh"
mkdir -p "$HOME/.config/environment.d"
sed -nE 's/^[[:space:]]*export[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)=(.*)$/\1=\2/p' \
  "$REPO/config/session-env.sh" > "$HOME/.config/environment.d/10-session.conf"

env_count="$(grep -c . "$HOME/.config/environment.d/10-session.conf" || true)"
if [ "$env_count" -gt 0 ]; then
  info "environment.d/10-session.conf — $env_count biến"
else
  warn "Không sinh được biến nào — app chạy qua systemd service sẽ thiếu IME."
fi

systemctl --user daemon-reexec 2>/dev/null || true

# ── 4. Thư mục dữ liệu người dùng ──────────────────────────
step "Tạo thư mục dữ liệu"
mkdir -p "$HOME/Pictures/wallpapers" "$HOME/Pictures/Screenshots" "$HOME/Books"

mkdir -p "$HOME/.config/quick-lang"
chmod 700 "$HOME/.config/quick-lang"
if [ -s "$HOME/.config/quick-lang/api.key" ]; then
  info "api.key (đã có, quyền $(stat -c%a "$HOME/.config/quick-lang/api.key"))"
else
  warn "Chưa có API key Gemini → Super+T (dịch) sẽ rơi về Google Translate."
  warn "  cp <file> ~/.config/quick-lang/api.key && chmod 600 ~/.config/quick-lang/api.key"
  warn "  hoặc đặt biến môi trường GEMINI_API_KEY."
fi
info "~/Pictures/{wallpapers,Screenshots}  ~/Books  ~/.config/quick-lang"

# ── 5. Plugin yazi ──────────────────────────────────────────
step "Cài plugin yazi (smart-enter)"
YAZI_PLUGIN="$HOME/.config/yazi/plugins/smart-enter.yazi"
if [ -d "$YAZI_PLUGIN" ]; then
  info "Đã có, giữ nguyên."
else
  command -v git >/dev/null || sudo pacman -S --needed --noconfirm git
  git clone --depth 1 https://github.com/yazi-extensions/smart-enter "$YAZI_PLUGIN" \
    && info "OK" || warn "Không clone được (mạng?) — bỏ qua, yazi vẫn chạy."
fi

# ── 6. Ứng dụng AppImage ───────────────────────────────────

# ── 7. Locale ──────────────────────────────────────────────
step "Sinh locale"
if ! locale -a 2>/dev/null | grep -qix 'en_US.utf8'; then
  sudo sed -i 's/^#\(en_US.UTF-8\)/\1/' /etc/locale.gen
  sudo locale-gen >/dev/null && info "en_US.UTF-8"
else
  info "đã có"
fi

# ── 8. Dịch vụ hệ thống ────────────────────────────────────
step "Bật dịch vụ hệ thống"
for svc in earlyoom keyd greetd fwupd; do
  sudo systemctl enable --now "$svc" 2>/dev/null && info "$svc" || warn "$svc: bật không được"
done
sudo systemctl enable --now fstrim.timer 2>/dev/null && info "fstrim.timer"

sudo systemctl mask systemd-oomd.service >/dev/null 2>&1 && info "mask systemd-oomd"

sudo systemctl enable battery-threshold.service 2>/dev/null \
  && info "battery-threshold.service" \
  || warn "battery-threshold: chưa thấy /usr/local/bin/set-battery-threshold"

# ── 9. Dịch vụ người dùng ──────────────────────────────────
step "Bật dịch vụ người dùng"
systemctl --user daemon-reload

systemctl --user enable --now trash-clean.timer 2>/dev/null \
  && info "trash-clean.timer" || warn "trash-clean.timer: bật không được"

systemctl --user enable wallpaper-init.service 2>/dev/null \
  && info "wallpaper-init.service" || warn "wallpaper-init.service: bật không được"

loginctl enable-linger "$USER" 2>/dev/null && info "linger: bật" || true

# ── 10. Kiểm tra ────────────────────────────────────────────
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

# ── 11. Git identity ────────────────────────────────────────
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

# ── 12. Gợi ý cuối ─────────────────────────────────────────
printf '\n%s✔ Xong.%s\n' "$C_G" "$C_0"
[ "$miss" -eq 1 ] && printf '%s  Còn thiếu gói ở trên — chạy lại ./install.sh khi có mạng.%s\n' "$C_Y" "$C_0"
