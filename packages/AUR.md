# Gói ngoài kho chính — cài khi thật sự cần

Dotfiles này **cố ý không phụ thuộc AUR**: `packages/official.txt` chỉ gói
trong `core`/`extra` nên `pacman -Syu` nhanh, không bao giờ vỡ vì build
lỗi. File này liệt kê những gói đã cân nhắc nhưng bỏ ra, kèm lý do.

## AUR helper

```bash
sudo pacman -S --needed --noconfirm git base-devel
git clone https://aur.archlinux.org/paru.git /tmp/paru && cd /tmp/paru && makepkg -si
```

Rồi mọi lệnh dưới đây thay bằng `paru -S <tên>`.

## Bảng

| Gói | Vì sao bỏ | Cài khi |
|---|---|---|
| `visual-studio-code-bin` | 500 MB, AUR | cần viết Java/Gradle hoặc dùng extension AI |
| `google-chrome` | 450 MB, AUR | cần Chrome (không phải Chromium) |
| `obsidian` | 250 MB + Electron | dùng Obsidian |
| `sioyek-git` | AUR, bản community | đọc PDF khoa học. Cài xong thêm vào `config/mimeapps.list`: `application/pdf=sioyek.desktop` |
| `goldendict-ng` | 200 MB + Qt WebEngine | tra từ điển StarDict. Cài xong gắn lại phím `$mod+g` trong `config/sway/config` |
| `tokyonight-gtk-theme` | AUR | muốn GTK theme Tokyo Night thay `Adwaita-dark` trong `config/gtk-3.0/settings.ini` |
| `bibata-cursor` | AUR | muốn con trỏ Bibata thay con trỏ mặc định |

## Preview trong yazi

`yazi` khai poppler/ffmpeg/resvg là **optdepends** — không cài thì yazi
chỉ hiện chữ, không hỏng. Thêm khi cần:

```bash
sudo pacman -S poppler        # preview PDF
sudo pacman -S ffmpeg         # preview video
sudo pacman -S resvg imagemagick chafa   # preview SVG, fallback ảnh ASCII
```

## Gỡ nhóm rườm rà từ NixOS cũ

Các mục dưới đây đã bị gỡ khỏi dotfiles (kèm lý do) — cài riêng nếu thay
đổi ý:

| Mục | Lý do bỏ |
|---|---|
| `direnv` + `nix develop` | không còn Nix. Dòng `eval "$(direnv hook bash)"` đã bỏ khỏi `~/.bashrc` |
| `nix-ld` | chỉ cần cho binary Nix trên hệ khác; Arch không cần |
| `appimage-run` | Arch đã có FUSE2, AppImage chạy thẳng sau `chmod +x` |
| `hyphenDicts` + symlink `/usr/share/hyphen` | trên NixOS `/usr/share` không có sẵn nên phải ép đường dẫn. Arch dùng gói `hyphen-en` là xong |
| `FCITX_ADDON_DIRS` / `FCITX_DATA_DIRS` | chỉ cần vì Nix đặt addon ngoài FHS. Arch đặt đúng chỗ |
| `vm-nixos` (script) | dùng để luyện cài NixOS trong QEMU. Muốn thì viết lại thành `vm-arch` |
| `sioyek-open`, `dict-toggle` | phụ thuộc app AUR ở trên |
