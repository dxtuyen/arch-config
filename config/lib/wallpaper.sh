#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
#  Thư viện dùng chung cho wallpaper-set / wallpaper-menu.
#  Nguồn:  . "${XDG_CONFIG_HOME:-$HOME/.config}/lib/wallpaper.sh"
#
#  Tách ra vì CẢ HAI script đều cần biết ảnh nằm ở đâu và ảnh nào
#  đang hiện. Để rải ở 2 nơi là chỗ dễ trôi nhất — đổi thư mục ảnh ở
#  file này thì cả hai cùng đúng.
# ══════════════════════════════════════════════════════════════

# Ảnh nằm NGOÀI repo: thêm/xoá bằng cp/rm, không cần cài lại dotfiles.
# Ảnh nền KHÔNG nằm trong git vì file ảnh nặng và mỗi máy một bộ.
WALL_DIR="${WALL_DIR:-$HOME/Pictures/wallpapers}"

# Màu nền dự phòng khi chưa có ảnh nào — Tokyo Night, khớp foot/sway.
# awww nhận thẳng hex nên không cần file ảnh, 0 byte trong repo.
FALLBACK_COLOR="0x1a1b26"

# Thời gian chuyển cảnh (giây). Số càng nhỏ càng "giật"; 1.5 là điểm
# mượt mà không làm chờ lâu.
FADE_DURATION=1.5

# Ảnh đang hiển thị, dạng canonical (đường dẫn tuyệt đối, symlink đã
# resolve). Trả về RỖNG khi: nền là màu trơn, daemon chưa sẵn sàng,
# hoặc aww trả về thứ gì không phải đường dẫn file.
#
# ⚠️ CỐ Ý KHÔNG có file cache riêng (kiểu ~/.cache/wallpaper-current):
#    awww đã tự cache ảnh phiên trước ở ~/.cache/awww. Thêm một nguồn
#    state thứ hai chỉ tạo cơ hội lệch nhau — lúc awww đổi ảnh nhưng
#    cache ta chưa, con trỏ ● trong menu trỏ nhầm ảnh.
wallpaper_current() {
  local raw
  raw="$(awww query 2>/dev/null | sed -n 's/.*currently displaying: image: //p' | head -1)"
  [ -n "$raw" ] || return 0
  [ -f "$raw" ] || return 0      # aww trả hex (0x…) khi nền là màu trơn
  readlink -f -- "$raw"
}

# Danh sách ảnh, đã sort, mỗi phần tử là đường dẫn tuyệt đối.
# -xtype f: bỏ symlink hỏng (thùng rác yazi hay thư mục sync hay tạo).
wallpaper_list() {
  find "$WALL_DIR" -maxdepth 1 -xtype f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) 2>/dev/null | sort
}

# Bảo đảm daemon sống. systemctl start TRẢ VỀ khi unit đã lên, và awww
# dựng socket ngay khi daemon lên — không cần vòng lặp chờ.
# Trả về 0 nếu daemon sẵn sàng trả lời.
wallpaper_ensure_daemon() {
  systemctl --user start awww-daemon.service 2>/dev/null || true
  awww query >/dev/null 2>&1
}
