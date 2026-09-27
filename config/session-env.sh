# ══════════════════════════════════════════════════════════════
#  Biến môi trường cho phiên Sway
#
#  ⭐ ĐÂY LÀ NGUỒN DUY NHẤT. Không tự viết thêm ở đâu khác.
#  install.sh đọc file này rồi SINH RA ~/.config/environment.d/
#  cho các app chạy qua systemd user service (swayidle, awww, fcitx5).
#  Sửa biến ở đây, chạy lại ./install.sh là xong — không có chuyện
#  sửa một nơi, quên chỗ kia.
#
#  Nạp bởi `usr/local/bin/start-sway` — wrapper mà `tuigreet --cmd` gọi
#  SAU khi đã xác thực, nên đây đúng là trong phiên user thật.
#  App Sway mở ra đều kế thừa các biến này. Đổi xong thì
#  Super+Shift+C để nạp lại, hoặc logout/login lại.
# ══════════════════════════════════════════════════════════════

# ── Fcitx5 (bộ gõ) ─────────────────────────────────────────
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export GDK_IM_MODULE=fcitx
# Buộc Qt dùng theme GTK3 → đồng bộ với ~/.config/gtk-3.0.
export QT_QPA_PLATFORMTHEME=gtk3

# ── Electron / Chromium chạy NATIVE Wayland ────────────────
# Không có biến này thì app chạy qua XWayland: chậm hơn, cửa sổ không
# bo góc, không share cơ chế với Sway. Thay cho NIXOS_OZONE_WL kiểu cũ.
export ELECTRON_OZONE_PLATFORM_HINT=auto
