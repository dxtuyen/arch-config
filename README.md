# arch-config

Dotfiles cho **Arch Linux + Sway (Wayland)**, theme Tokyo Night.
Một lệnh cài, một lệnh gỡ. Tái lập lại máy mới trong ~20 phút.

```bash
git clone https://github.com/dxtuyen/arch-config.git ~/arch-config
cd ~/arch-config && ./install.sh
```

**Cài máy mới từ đầu (từ USB trở đi):** xem
[Cài máy mới từ đầu](#cài-máy-mới-từ-đầu) — 5 bước, phần cài tay gộp
thành 1 lệnh `bootstrap.sh`, kèm bảng chẩn đoán sự cố.

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
├── bootstrap.sh              # ⭐ cài MÁY MỚI từ USB: 1 lệnh
├── install.sh                # cài dotfiles lên hệ thống đã có
├── packages/
│   ├── official.txt        # gói pacman, không AUR
│   └── AUR.md              # gói đã cân nhắc + lý do bỏ
├── config/                 # stow → ~/.config/
│   ├── sway/config         # ⭐ cấu hình chính
│   ├── waybar/config.jsonc
│   ├── foot/foot.ini · mako/config · starship.toml
│   ├── fcitx5/{profile,conf/bamboo.conf}
│   ├── yazi/{yazi,keymap,theme}.toml
│   ├── lib/wallpaper.sh    # hằng số + hàm dùng chung cho script ảnh nền
│   ├── session-env.sh      # ⭐ nguồn biến môi trường DUY NHẤT
│   ├── mimeapps.list · gtk-3.0/settings.ini · xfce4/helpers.rc
│   └── systemd/user/       # swayidle, awww-daemon, wallpaper-init,
│                           # trash-clean(+timer), fcitx5
├── home/                   # stow → ~/
│   ├── .gitconfig · .bashrc
│   ├── .local/bin/         # 18 script
│   └── .local/share/applications/
├── etc/                    # stow → /etc
│   ├── greetd/config.toml  # ⚠️ PHẢI ở /etc, không phải ~/.config
│   ├── keyd/default.conf · default/earlyoom
│   ├── systemd/zram-generator.conf · systemd/logind.conf.d/
│   ├── systemd/system/battery-threshold.service
│   ├── kernel/cmdline · mkinitcpio.conf · locale.conf · hostname
│   └── pacman.d/mirrorlist · sudoers.d/wheel
├── usr/local/bin/          # stow → /usr/local/bin
│   ├── start-sway          # wrapper greetd gọi sau khi đăng nhập
│   └── set-battery-threshold
└── lockscreen/lockscreen.png
```

> ⚠️ **`greetd/config.toml` nằm trong `etc/`, không phải `config/`.** Đây
> là chỗ duy nhất phá vỡ quy tắc "mọi thứ trong `config/` đều là
> `~/.config`". Lý do: greetd chỉ đọc `/etc/greetd/config.toml`
> (man greetd(1)) — không có đường dẫn theo user như `~/.config/`.
> Đặt nhầm vào `~/.config/greetd/` thì greetd im lặng dùng config mặc
> định, bạn đăng nhập được nhưng rơi vào shell trần — không có Sway.

> `config/environment.d/` **không có trong repo**: `install.sh` sinh ra từ
> `session-env.sh` mỗi lần chạy, nên không thể lệch hai nơi.

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

> Thứ tự dưới đây là **bắt buộc** — mỗi bước cần bước trước làm xong mới
> được đi tiếp. Riêng Bước 4 (xoá phân vùng) và Bước 6 (bootloader) sai
> thì **không cứu được**, phải cài lại từ đầu.
>
> Ổ cứng máy này là `/dev/nvme0n1`. USB luôn là `/dev/sdX`. Nhầm hai thứ
> là mất sạch — luôn kiểm `lsblk` trước khi ghi bất cứ thứ gì.

### Bước 0 · Backup dữ liệu (đã xong — nhưng đừng bỏ, làm cho máy khác)

Ba thứ **không có trong git**, mất là mất:

```bash
mkdir -p ~/Downloads/backup
cp ~/.config/quick-lang/api.key ~/Downloads/backup/   # key Gemini
cp -r ~/Pictures/wallpapers  ~/Downloads/backup/     # ảnh nền
cp -r ~/Books               ~/Downloads/backup/     # sách
ls -lhR ~/Downloads/backup
```

Copy ra **USB hoặc đĩa ngoài** — backup trong ổ sắp bị xoá là vô nghĩa:

```bash
sudo mkdir -p /mnt/usb && sudo mount /dev/sda1 /mnt/usb
mkdir -p /mnt/usb/backup && cp -r ~/Downloads/backup/* /mnt/usb/backup/
sync && sudo umount /mnt/usb
```

> `~/Apps/RemNote` **không** cần copy — máy mới tải lại AppImage từ
> `~/Downloads` rồi chạy `setup-remnote`.

### Bước 1 · Ghi USB boot

```bash
cd ~/Downloads
# Kiểm tra ISO — phải in "OK"
grep 'archlinux-2026.09.01-x86_64.iso' sha256sums.txt | sha256sum -c -

lsblk -o NAME,SIZE,TYPE,FSTYPE,MODEL,TRAN     # xác định USB, ĐỪNG chọn nvme0n1

sudo dd if=archlinux-2026.09.01-x86_64.iso of=/dev/sdX \
     bs=4M status=progress conv=fsync
sync
```

> ⛔ `dd` vào `/dev/nvme0n1` = **xoá sạch NixOS trong 3 giây**.

### Bước 2 · Boot từ USB

1. **Rút USB** khỏi cổng đang cắm.
2. Cắm vào **cổng USB khác** (USB vừa ghi thường không boot ở chính cổng đó).
3. Bật máy, nhấn **`F12`** ngay (ThinkPad Lenovo) → chọn USB.
4. Chọn hạng mục đầu tiên (Arch Linux).

Vào được màn hình đen chữ trắng `root@archlinux#` là thành công.

<details>
<summary>Không thấy USB trong menu boot?</summary>

- Thử **cổng USB khác** — ưu tiên cổng A2/C2 màu xanh (chậm hơn nhưng ổn định hơn với USB 3.0).
- BIOS (nhấn `F1` khi bật máy) → kiểm tra **USB Boot** đã bật.
- Một số ThinkPad cần bật **USB UEFI Boot** trong `Security → Secure Boot`.

</details>

### Bước 3 · Kết nối mạng

```bash
iwctl                                # nếu dùng Wi-Fi
device list                          # thường là wlan0
station wlan0 connect <TÊN-WIFI>     # nhập mật khẩu
# "Password authentication successful" → exit

ping -c3 archlinux.org               # phải được 3 replies
timedatectl set-ntp true             # đồng hồ đúng, pacman mới không lỗi chữ ký
```

> ⛔ **Không có mạng thì dừng.** `pacstrap` tải được 0 gói. Thử: đổi cổng
> USB, hoặc dùng điện thoại làm hotspot.

### Bước 4 · Phân vùng — ⚠️ XOÁ SẠCH NIXOS

⛔ **Bước này xoá toàn bộ NixOS.** Chỉ chạy được ở live shell, vì ở hệ
thống đang chạy thì `/` và `/boot` đang mount — xoá là sập ngay.

```bash
# Xác nhận lần cuối: nvme0n1 KHÔNG phải USB
lsblk -o NAME,SIZE,TYPE,FSTYPE,MODEL,TRAN

sudo wipefs -a /dev/nvme0n1
sudo sgdisk --zap-all /dev/nvme0n1
lsblk                                  # nvme0n1 phải trống, hết partition

sudo cfdisk /dev/nvme0n1
#   1 GiB      →  EFI System        (phân vùng 1)
#   còn lại    →  Linux filesystem  (phân vùng 2)
#   → Write → Yes
```

> ⛔ **KHÔNG tạo swap.** Máy có 7.4 GiB RAM, `deep sleep` đủ dùng, zram lo
> phần RAM còn dư. Swap 8 GiB chỉ phục vụ hibernate — mà máy này không
> dùng hibernate.

```bash
sudo mkfs.fat -F32 /dev/nvme0n1p1
sudo mkfs.ext4   /dev/nvme0n1p2
sudo mount      /dev/nvme0n1p2 /mnt
sudo mount --mkdir /dev/nvme0n1p1 /mnt/boot
```

### Bước 5 · Cài hệ thống + dotfiles — 1 lệnh

```bash
git clone https://github.com/dxtuyen/arch-config.git
sudo arch-config/bootstrap.sh
```

Gõ chữ **`phai`** để xác nhận. Từ đó để máy chạy ~10 phút, không cần gõ
thêm gì.

`bootstrap.sh` làm hết: `pacstrap` (kèm `sudo git efibootmgr intel-ucode`) ·
múi giờ · locale · fstab bằng UUID · user + sudo · NetworkManager + iwd ·
clone dotfiles + `install.sh` · `mkinitcpio -P` · `bootctl install`.

**Đăng nhập sau khi reboot:** user `doxuantuyen` · mật khẩu `63795664`
(đổi ngay ở Bước 7).

#### Vì sao script riêng, không dùng `archinstall` của Arch

1. **Đọc `schema.json` của `archinstall` (18 trường):** không có
   `kernel_params`, không có `hibernate`/`swap`. Không cài `intel-ucode`
   (thiếu thì **kernel có thể không khởi động** trên CPU Intel), không
   `git`, mặc định cài **LightDM** chứ không greetd.
2. **Thứ tự deep sleep** — phần này không thể sai:
   ```
   install.sh stow etc/kernel/cmdline → mkinitcpio -P → bootctl install
   ```
   `archinstall` không cho kiểm soát thứ tự. Gộp 2 bước sau ra trước thì
   initramfs không có `deep`; làm `bootctl` sớm thì không có entry boot.

<details>
<summary>Cài tay từng bước (để học trên máy ảo)</summary>

Không dùng `bootstrap.sh`, làm tay theo thứ tự này. Thứ tự **bắt buộc** —
đặc biệt bootloader phải cài **trước khi reboot**, không thì máy không
khởi động được.

```bash
# --- Trong chroot sau pacstrap ---
pacman-key --init && pacman-key --populate archlinux
pacman -Syu

# ⚠️ NetworkManager, KHÔNG systemd-networkd — dotfiles chạy trên nó
#    (nm-applet trong sway/config, nmcli trong quick-net-reload).
pacman -S --needed networkmanager iwd
systemctl enable NetworkManager.service
cat > /etc/NetworkManager/NetworkManager.conf <<'EOF2'
[main]
dns=systemd-resolved
wifi.backend=iwd
[connection]
wifi.cloned-mac-address=stable
EOF2
systemctl enable systemd-resolved.service
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# ⛔ THIẾU FILE NÀY THÌ MÁY KHÔNG CÓ WIFI
mkdir -p /etc/systemd/network
cat > /etc/systemd/network/20-wifi.network <<'EOF3'
[Match]
Name=wlan0 wlp*
[Network]
DHCP=yes
IPv6AcceptRA=yes
EOF3

useradd -m -G wheel -s /bin/bash <TÊN> && passwd <TÊN>
echo '%wheel ALL=(ALL:ALL) ALL' > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel
visudo -c -f /etc/sudoers.d/wheel      # phải báo "parsed OK"

sed -i 's/^#\(en_US.UTF-8\)/\1/' /etc/locale.gen
locale-gen && echo 'LANG=en_US.UTF-8' > /etc/locale.conf
ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime && hwclock --systohc

# fstab BẮT BUỘC UUID — tên /dev/sdX không ổn định giữa các lần boot
ROOT_UUID=$(blkid -s UUID -o value /dev/nvme0n1p2)
ESP_UUID=$(blkid -s UUID -o value /dev/nvme0n1p1)
printf 'UUID=%s / ext4 defaults,noatime 0 1\n'  "$ROOT_UUID" >> /etc/fstab
printf 'UUID=%s /boot vfat defaults,fmask=0077,dmask=0077 0 2\n' "$ESP_UUID" >> /etc/fstab

# --- Dotfiles ---
su - <TÊN> && git clone https://github.com/dxtuyen/arch-config.git ~/arch-config
cd ~/arch-config && ./install.sh
sudo chmod 440 /etc/sudoers.d/wheel && sudo visudo -c -f /etc/sudoers.d/wheel
exit
```

**Bootloader — sau khi `install.sh` đã stow `etc/kernel/cmdline`:**

```bash
cat /etc/kernel/cmdline               # phải thấy mem_sleep_default=deep
grep microcode /etc/mkinitcpio.conf   # phải có hook này
mkinitcpio -P
bootctl install                      # ⚠️ cần ESP đang mount ở /mnt/boot
kernel-install add-all "$(ls /usr/lib/modules | sort -V | tail -1)"
bootctl list                         # phải thấy entry + "Default EFI"
exit
```

</details>

### Bước 6 · Reboot

⛔ **Đợi tới khi `bootstrap.sh` in "XONG — có thể reboot"** và `bootctl list`
có entry. Nếu script báo lỗi ở bước bootloader, **đừng reboot**.

```bash
umount -R /mnt
reboot
```

**Rút USB trước khi reboot** — nếu không, BIOS có thể lại boot từ USB.

### Bước 7 · Đăng nhập + kiểm tra

Đăng nhập: user `doxuantuyen` · mật khẩu `63795664`
Hostname: `archbook` (đổi ở `etc/hostname` hoặc dòng `HOSTNAME=` trong
`bootstrap.sh`)

```bash
systemctl --failed                   # phải TRỐNG
systemctl --user --failed            # phải TRỐNG
systemctl --user list-timers | grep trash   # phải thấy trash-clean
fcitx5-remote -n | grep -q bamboo && echo 'Bamboo OK'
free -h | grep zram0                 # phải thấy /dev/zram0
```

**Ngay sau khi vào Sway, làm 3 việc này:**

```bash
# 1. Đổi mật khẩu — 63795664 nằm trong bootstrap.sh và lịch sử git
passwd

# 2. Khôi phục key Gemini + ảnh nền từ backup
mkdir -p ~/.config/quick-lang ~/Pictures/wallpapers
cp -v /đường/dẫn/backup/api.key    ~/.config/quick-lang/
cp -rv /đường/dẫn/backup/wallpapers/* ~/Pictures/wallpapers/
chmod 600 ~/.config/quick-lang/api.key
# Thử: Super+T → dịch tiếng Việt

# 3. Cài app cần thêm (xem "Cài thêm sau")
```

**Đổi API key Gemini:** <https://aistudio.google.com/apikey> — key cũ đã
bị GitHub nhận vào hệ thống quét secret lúc thử push.

| Triệu chứng | Nguyên nhân thường gặp |
|---|---|
| **Đăng nhập xong rơi vào `/bin/sh`, không có Sway** | greetd không đọc `~/.config/greetd/config.toml`. Kiểm: `sudo cat /etc/greetd/config.toml` phải thấy `tuigreet` |
| Không lên màn hình đăng nhập | `bootctl list` rỗng → `bootctl install` chạy lúc ESP chưa mount |
| Vào Sway nhưng không gõ được tiếng Việt | `systemctl --user status fcitx5` → đọc log |
| Không có mạng | thiếu `/etc/systemd/network/20-wifi.network` |
| Máy không boot | `/etc/fstab` sai UUID → đọc log trên màn hình initramfs |
| `sudo` báo "not in the sudoers file" | `/etc/sudoers.d/wheel` quyền ≠ 440 → `sudo chmod 440` |

Mất màn hình đăng nhập thì sửa được từ TTY khác: `Ctrl+Alt+F2`, đăng
nhập, rồi thêm `systemd.mask=greetd.service` vào `/etc/kernel/cmdline`
để tạm lấy lại `agetty` mà sửa cấu hình.

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
