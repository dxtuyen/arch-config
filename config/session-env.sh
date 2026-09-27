# ══════════════════════════════════════════════════════════════
#  Biến môi trường cho phiên Sway
#
#  Nạp bởi greetd (`sh -c '. ~/.config/session-env.sh; exec sway'`).
#  Mọi app Sway mở ra đều kế thừa các biến này. Đổi xong thì
#  Super+Shift+C để nạp lại, hoặc logout/login lại.
#
#  App mở qua SYSTEMD USER SERVICE thì không thừa hưởng biến ở đây —
#  những app đó lấy biến từ ~/.config/environment.d/ (giữ hai nơi
#  đồng bộ).
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
