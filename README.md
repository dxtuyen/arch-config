# arch-config

Dotfiles cho **Arch Linux + Sway (Wayland)**, theme Tokyo Night.
Một lệnh cài, một lệnh gỡ. Tái lập lại máy mới trong ~20 phút.

```bash
git clone <url-repo> ~/arch-config && cd ~/arch-config && ./install.sh
```

**Cài máy mới từ đầu (từ USB trở đi):** xem [Cài máy mới từ đầu](#cài-máy-mới-từ-đầu) —
6 bước, có lệnh copy-paste và bảng chẩn đoán sự cố.

| | |
|---|---|
| 🖥️ Hệ thống | Arch Linux (systemd-boot) |
| 🪟 Desktop | Sway + Waybar + Mako + greetd/tuigreet |
| 🎨 Terminal | Foot + Starship |
| ⌨️ Bộ gõ | Fcitx5 + Bamboo (Telex) |
| 📦 Cài đặt | pacman, **không AUR**, không Nix |
| 🔧 Quản lý | GNU Stow + `install.sh` |

---

## Cấu trúc

```
arch-config/
├── install.sh              # 1 lệnh cài tất cả
├── packages/
│   ├── official.txt        # gói pacman, không AUR
│   └── AUR.md              # gói đã cân nhắc + lý do bỏ
├── config/                 # stow → ~/.config/
│   ├── sway/config         # ⭐ cấu hình chính
│   ├── waybar/config.jsonc
│   ├── foot/foot.ini · mako/config · starship.toml
│   ├── fcitx5/{profile,conf/bamboo.conf}
│   ├── yazi/{yazi,keymap,theme}.toml
│   ├── greetd/config.toml · session-env.sh
│   ├── lib/wallpaper.sh    # hằng số + hàm dùng chung cho script ảnh nền
│   ├── environment.d/10-session.conf
│   ├── mimeapps.list · gtk-3.0/settings.ini · xfce4/helpers.rc
│   └── systemd/user/       # swayidle, awww-daemon, wallpaper-init,
│                           # trash-clean(+timer), fcitx5
├── home/                   # stow → ~/
│   ├── gitconfig · bashrc
│   ├── .local/bin/         # 18 script
│   └── .local/share/applications/
├── etc/                    # stow → /etc
│   ├── keyd/default.conf · default/earlyoom
│   ├── systemd/zram-generator.conf · systemd/logind.conf.d/
│   ├── systemd/system/battery-threshold.service
│   ├── kernel/cmdline · mkinitcpio.conf · locale.conf
│   └── pacman.d/mirrorlist · sudoers.d/wheel
├── usr/local/bin/          # stow → /usr/local/bin
└── lockscreen/lockscreen.png
```

> **Ảnh khoá màn hình:** `lockscreen/lockscreen.png` lấy từ
> [LagrangianLad/arch-minimal-wallpapers](https://github.com/LagrangianLad/arch-minimal-wallpapers)
> (bản `material-darker`) — MIT, © 2021 Pablo Corbalán. Bản gốc kèm
> license ở `lockscreen/LICENSE-wallpaper.txt`. Muốn đổi thì thay file
> trong `lockscreen/`, không cần sửa gì thêm. Repo đó có 33 bản màu
> theo palette của các theme nổi tiếng (`rosepine`, `nord`, `onedark`,
> `tokyonight`…).

**Cơ chế:** file trong repo được `stow` thành symlink ở đích. Sửa ở đâu
cũng được — sửa trong repo thì có version control, sửa ở `~` cũng được
vì nó là symlink trỏ về repo. `install.sh` dùng `--overwrite`: nếu app
đã tự tạo file trùng tên, file cũ được đổi tên thành `*.stow-backup`,
không bị xoá.

## Cài máy mới từ đầu

> Thứ tự dưới đây là **bắt buộc**. Đặc biệt: bootloader phải cài **trước
> khi reboot**, nếu không máy sẽ không khởi động được.
>
> Thay `<TÊN>` bằng tên user thật, `<REPO>` bằng URL repo dotfiles,
> `/dev/nvme0n1` bằng ổ của bạn (kiểm bằng `lsblk`).

### Bước 0 · Ghi USB boot

```bash
lsblk                                    # xác định đúng ổ USB — ĐỪNG chọn nhầm ổ cứng
sudo dd if=archlinux-x86_64.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

### Bước 1 · Phân vùng (không tạo swap)

```bash
cfdisk /dev/nvme0n1
#   1 GiB   EFI System        → /dev/nvme0n1p1
#   còn lại Linux filesystem → /dev/nvme0n1p2

mkfs.fat -F32 /dev/nvme0n1p1
mkfs.ext4   /dev/nvme0n1p2
mount      /dev/nvme0n1p2 /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot
```

### Bước 2 · Cài hệ thống tối thiểu

```bash
# ⛔ sudo và git KHÔNG nằm trong nhóm `base`. Thiếu sudo thì không làm
#    được gì cả; thiếu git thì Bước 3 không clone được dotfiles.
pacstrap -K /mnt base linux linux-firmware systemd mkinitcpio \
    sudo git efibootmgr intel-ucode

arch-chroot /mnt
```

**Trong chroot:**

```bash
# Khoá pacman (sau pacstrap phải làm, nếu không `pacman -S` sẽ lỗi)
pacman-key --init
pacman-key --populate archlinux
pacman -Syu

# Mirror
echo 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch' > /etc/pacman.d/mirrorlist
pacman -Sy

# ⚠️ Dùng NetworkManager NGAY TỪ ĐẦU — dotfiles chạy trên nó (nm-applet,
#    nmcli trong quick-net-reload, networkmanagerapplet). Cài thêm
#    systemd-networkd/resolved ở bước này sẽ đụng đội: hai trình cùng
#    quản lý interface, rất khó chẩn đoán khi có sự cố.
pacman -S --needed networkmanager iwd
systemctl enable NetworkManager.service
cat > /etc/NetworkManager/NetworkManager.conf <<'EOF'
[main]
dns=systemd-resolved
wifi.backend=iwd
[connection]
wifi.cloned-mac-address=stable
EOF
systemctl enable systemd-resolved.service
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# ⛔ THIẾU FILE NÀY THÌ MÁY KHÔNG CÓ WIFI
#    (iwd + NetworkManager không tự sinh file này)
cat > /etc/systemd/network/20-wifi.network <<'EOF'
[Match]
Name=wlan0 wlp*
[Network]
DHCP=yes
IPv6AcceptRA=yes
EOF

# User + sudo
useradd -m -G wheel -s /bin/bash <TÊN>
passwd <TÊN>
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel
visudo -c -f /etc/sudoers.d/wheel      # phải báo "parsed OK"

# Locale (install.sh cũng làm, nhưng làm sớm ở đây cho chắc)
sed -i 's/^#\(en_US.UTF-8\)/\1/' /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

# Múi giờ
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime
hwclock --systohc

# fstab — BẮT BUỘC dùng UUID.
# ⚠️ Tên /dev/sdX KHÔNG ổn định giữa các lần boot (thứ tự nhận thiết bị
#    đổi theo lần khởi động), dùng nó thì có lần máy không mount được root.
ROOT_UUID=$(blkid -s UUID -o value /dev/nvme0n1p2)
ESP_UUID=$(blkid -s UUID -o value /dev/nvme0n1p1)
printf 'UUID=%s / ext4 defaults,noatime 0 1\n'  "$ROOT_UUID" >> /etc/fstab
printf 'UUID=%s /boot vfat defaults,fmask=0077,dmask=0077 0 2\n' "$ESP_UUID" >> /etc/fstab
cat /etc/fstab                         # kiểm tra lại trước khi đi tiếp
```

### Bước 3 · Cài dotfiles

```bash
su - <TÊN>
git clone <REPO> ~/arch-config
cd ~/arch-config && ./install.sh

# ⚠️ Stow tạo symlink nhưng KHÔNG giữ quyền của file trong repo, nên
#    /etc/sudoers.d/wheel ra 644 và sudo SẼ IM LẶNG BỎ QUA — mất quyền
#    admin mà không có dòng cảnh báo nào. install.sh đã tự sửa, làm tay
#    thêm một lần cho chắc trước khi rời chroot:
sudo chmod 440 /etc/sudoers.d/wheel
sudo visudo -c -f /etc/sudoers.d/wheel

exit
```

### Bước 4 · Cài bootloader **trước khi reboot**

```bash
arch-chroot /mnt

# mkinitcpio.conf đã có hook `microcode` (do install.sh stow từ repo)
# và intel-ucode đã cài → initramfs có microcode. Thiếu cái này thì
# kernel có thể không khởi động trên một số CPU Intel.
mkinitcpio -P

bootctl install                 # ⚠️ cần ESP đang mount ở /mnt/boot
kernel-install add-all "$(ls /usr/lib/modules | sort -V | tail -1)"
bootctl list                    # phải thấy entry + "Default EFI"
exit
```

### Bước 5 · Reboot

```bash
umount -R /mnt
reboot
```

Đăng nhập bằng user đã tạo. greetd/tuigreet hiện ra → nhập tên →
mật khẩu → Sway tự lên.

### Bước 6 · Kiểm tra sau lần boot đầu

```bash
systemctl --user --failed            # phải TRỐNG
systemctl --failed                   # phải TRỐNG
systemctl --user list-timers | grep trash   # phải thấy trash-clean
fcitx5-remote -n | grep -q bamboo && echo 'Bamboo OK'
free -h                             # phải thấy /dev/zram0
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT
systemctl --user status wallpaper-init
```

| Triệu chứng | Nguyên nhân thường gặp |
|---|---|
| Không lên màn hình đăng nhập | `bootctl list` rỗng → `bootctl install` chạy lúc ESP chưa mount |
| Vào Sway nhưng không gõ được tiếng Việt | `systemctl --user status fcitx5` → đọc log |
| `sudo: command not found` | quên `pacman -S sudo` ở Bước 2 |
| Không có mạng | thiếu `/etc/systemd/network/20-wifi.network` |
| Máy không boot | `/etc/fstab` sai UUID → đọc log trên màn hình initramfs |
| `sudo` báo "not in the sudoers file" | `/etc/sudoers.d/wheel` quyền ≠ 440 → `sudo chmod 440` |

---

## Vận hành hằng ngày

```bash
sudo pacman -Syu                    # cập nhật hệ thống
git pull --rebase && ./install.sh   # cập nhật dotfiles (tự cài gói mới nếu có)
./install.sh --skip-packages        # chỉ cài lại dotfiles, không đụng gói
./install.sh --uninstall            # gỡ symlink (dữ liệu giữ nguyên)
```

Sửa cấu hình xong → `Super+Shift+C` nạp lại Sway.
Sửa `~/.config/systemd/user/*.service` → `systemctl --user daemon-reload && systemctl --user restart <tên>`.

### Phím tắt chính

| Phím | Việc |
|---|---|
| `Super+d` | launcher |
| `Super+Enter` | terminal |
| `Super+y` | yazi popup · `Super+Tab` đổi cửa sổ |
| `Super+p` | đồng hồ Focus · `Super+Shift+p` menu nguồn |
| `Super+t` / `Shift+t` / `Ctrl+Shift+t` | dịch sang EN / sang VI / sửa EN |
| `Super+1..4` | workspace · `Super+u` / `Super+i` trước–sau |
| `Super+Shift+C` | nạp lại session · `Super+Shift+L` khoá màn |
| `Print` + `Alt/Shift/Ctrl` | chụp vùng / toàn màn, clipboard / lưu file |
| `CapsLock` | giữ = Ctrl, chạm = Esc (keyd) |
| `Tab` + `hjkl` | giữ Tab = phím mũi tên (keyd) |

---

## Cấu hình hệ thống đáng chú ý

| Tính năng | Cách hoạt động |
|---|---|
| **Sạc pin 85–90%** | `battery-threshold.service` + `/usr/local/bin/set-battery-threshold` |
| **Swap nén zram** | `zram-generator`: 50% RAM, zstd |
| **Chống treo RAM** | `earlyoom` báo động ở 2%, `systemd-oomd` bị mask |
| **TRIM SSD** | `fstrim.timer` (có sẵn) |
| **Tự dọn thùng rác** | `trash-clean.timer` lúc 03:00, giữ 30 ngày, `Persistent=true` |
| **Khóa → tắt → ngủ** | `swayidle`: 300s / 310s / 900s (chỉ ngủ khi dùng pin) |
| **Timer Focus tự dừng khi ngủ** | hook `before-sleep` / `after-resume` của swayidle gọi `study` |
| **Ảnh nền có fade** | `awww-daemon` + `wallpaper-init.service`. `Alt+w` random · `Alt+Shift+w` chọn ảnh có thumbnail |
| **Đóng nắp → ngủ** | `/etc/systemd/logind.conf.d/10-laptop.conf` |
| **Firmware** | `fwupd` |

### Về ảnh nền — muốn bỏ thì bỏ được

`awww` là **lý do duy nhất** có toàn bộ phần ảnh nền này: Sway đổi nền
bằng `output * bg` được nhưng là **cắt cứng**, không có hiệu ứng; awww
cho fade 1.5s.

Nếu bạn không thấy khác biệt, thay bằng một dòng trong
`~/.config/sway/config`:

```
output * bg ~/Pictures/wallpapers/<tên>.jpg fill
```

rồi xoá: `awww` khỏi `packages/official.txt` · `wallpaper-set` ·
`wallpaper-menu` · `config/lib/wallpaper.sh` · `awww-daemon.service` ·
`wallpaper-init.service` · 2 phím `Alt+w` / `Alt+Shift+w`. Xoá xong
không còn gì chạy nền.

Ảnh nằm ở `~/Pictures/wallpapers` — **ngoài repo**, cp/rm tự do, không
cần cài lại dotfiles. Giống `~/Books` hay `~/.config/quick-lang`, thư mục
này **không có trong git** (ảnh nặng, và mỗi máy một bộ).

#### Máy mới: đưa ảnh vào thế nào

Ảnh cũ nằm ở ổ cứng hoặc máy cũ, copy sang thẳng:

```bash
mkdir -p ~/Pictures/wallpapers
cp -v /đường/dẫn/ảnh/*.{png,jpg,jpeg} ~/Pictures/wallpapers/ 2>/dev/null
# hoặc dùng đĩa USB:
cp -v /run/media/$USER/USB/wallpapers/* ~/Pictures/wallpapers/
```

Xong là xong, **không cần chạy `install.sh` lại**. `wallpaper-init.service`
tự động chạy mỗi lần đăng nhập: nếu `awww` đã giữ được ảnh phiên trước
thì giữ nguyên, chưa có thì random một ảnh.

**Chưa có ảnh nào cũng không sao** — nền là màu trơn `0x1a1b26` (Tokyo
Night), không lỗi gì. Thả ảnh vào sau, lần đăng nhập kế tiếp sẽ thấy.

Đổi ảnh ngẫu nhiên: `Alt+Shift+w` (rofi lưới 3×3 có thumbnail) · đặt
đúng một ảnh: `wallpaper-set <đường/dẫn/ảnh>`.

#### Muốn ảnh nền nằm trong git

Không khuyên — ảnh 2-4K mỗi tấm vài MB, và bộ ảnh là thứ cá nhân của
bạn. Nếu vẫn muốn (ví dụ chỉ 1 ảnh, ~200 KB):

```bash
# 1. Tạo symlink trong repo trỏ sang ảnh, thay vì copy nhị phân
ln -s ~/Pictures/wallpapers/<tên>.jpg lockscreen/
# 2. Bỏ dòng này khỏi .gitignore
#    Pictures/
git add lockscreen/ && git commit -m 'thêm ảnh nền'
```

Nên nhớ `awww` cache ảnh ở `~/.cache/awww` — máy mới clone repo vẫn
phải có ảnh thật ở `~/Pictures/wallpapers` mới hiện được.

---

## Dữ liệu KHÔNG nằm trong repo

`install.sh` tạo thư mục nhưng không tạo nội dung. Cần tự sao lưu:

| Đường dẫn | Là gì |
|---|---|
| `~/Pictures/wallpapers` | ảnh nền (thêm bằng `cp`, không cần cài lại) |
| `~/Pictures/Screenshots` | ảnh chụp màn |
| `~/Books` | sách điện tử / PDF |
| `~/Apps/RemNote/RemNote.AppImage` | AppImage RemNote (tải về `~/Downloads` rồi chạy `setup-remnote`) |
| `~/.config/quick-lang/api.key` | **secret** Gemini API key — chmod 600 |

Bí mật KHÔNG được commit: `.gitignore` đã chặn `config/quick-lang/`, `*.key`.

---

## Cài thêm sau

Gói nặng và gói AUR **cố ý không có** trong `packages/official.txt`.
Xem [`packages/AUR.md`](packages/AUR.md) để biết gói nào, cài khi nào,
lý do bỏ.

```bash
paru -S <tên>              # gói AUR (cần cài paru trước)
sudo pacman -S <tên>       # gói chính thức
```

Một số việc có thể muốn làm thêm:

```bash
sudo timedatectl set-local-rtc 1 --adjust-system-clock   # giữ đồng hồ Windows
sudo powerctl reboot                                          # bật power menu 2 giây
```


### 4. Bootloader systemd-boot

```bash
sudo mkinitcpio -P
sudo bootctl install
sudo kernel-install add-all "$(uname -r)"
```

Lần boot đầu tiên đăng nhập bằng user đã tạo. Sway tự lên.
