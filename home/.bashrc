# ══════════════════════════════════════════════════════════════
#  ~/.bashrc — chỉ áp dụng cho shell TƯƠNG TÁC. File login (biến môi
#  trường, PATH) nằm trong ~/.profile.
# ══════════════════════════════════════════════════════════════

# Không dùng bash ở TTY (nếu shell trong ~/.profile bị đổi) → thoát sớm,
# tránh chạy 2 lần khi mở cửa sổ con.
[[ $- != *i* ]] && return

# ── Lịch sử ────────────────────────────────────────────────
HISTFILE=~/.local/share/bash/history
mkdir -p "$(dirname "$HISTFILE")" 2>/dev/null
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend          # ghi thêm, không ghi đè khi có nhiều shell
shopt -s checkwinsize         # HISTSIZE tính lại theo kích thước cửa sổ
shopt -s autocd               # `..` và `cd` không cần gõ
shopt -s cdspell              # sửa gõ sai trong `cd`
shopt -s cmdhist              # nhiều lệnh trên 1 dòng lưu thành 1 mục
bind 'set completion-ignore-case on' 2>/dev/null

# ── Màu & alias ─────────────────────────────────────────────
# ⚠️ CỐ Ý KHÔNG alias `rm -i` / `cp -i` / `mv -i`: chúng làm khó chịu
#    kiểu hỏi lại ở mọi lệnh, và người dùng đã quen với việc xoá hàng
#    loạt. Bù lại, thùng rác vẫn là vùng an toàn: xoá mềm bằng `d` trong
#    yazi, khôi phục bằng `g t`, tự dọn sau 30 ngày.
alias ls='ls --color=auto --group-directories-first'
alias ll='ls -alhF --color=auto'
alias la='ls -A --color=auto'
alias ldot='ls -ld .*'
alias df='df -hT'
alias du='du -h'
alias free='free -h'
alias ps='ps aux --sort=-%mem'
alias ping='ping -c 5'
alias curl='curl -L --progress-bar'
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias journalctl='journalctl -p warning..alert --since=today'
alias ..='cd ..'

# ls màu: cột quyền dễ đọc hơn ký hiệu r,w,x
export LS_COLORS='di=01;34:ln=01;36:so=01;35:do=01;35:bd=01;33;40:cd=01;33;40:su=37;41:sg=30;43:tw=30;42:ow=34;42:st=37;44:ex=01;32'

# ── Môi trường ─────────────────────────────────────────────
export EDITOR=nvim
export VISUAL="$EDITOR"
export PAGER=less
export LESS='-R -F -X -M'      # giữ màu, không clear màn hình khi ngắn trang

# Ngôn ngữ ứng dụng — ảnh hưởng ngữ cảnh dịch của quick-lang
# (Gemini hiểu "vi" là tiếng Việt, "en" là tiếng Anh).
export LANG=en_US.UTF-8

# ── Công cụ ─────────────────────────────────────────────────
# starship: prompt (Tokyo Night)
command -v starship >/dev/null && eval "$(starship init bash)"

# zoxide: `z <tên>` nhảy thẳng tới thư mục hay đi
command -v zoxide >/dev/null && eval "$(zoxide init bash)"

# fzf: Ctrl+R tìm lịch sử, Ctrl+T tìm file
command -v fzf >/dev/null && eval "$(fzf --bash)"

# ── Tiêu đề cửa sổ terminal ────────────────────────────────
# Starship không set title nên tự phát OSC 2 mỗi prompt. Tách 2 bước để
# né tilde expansion làm title hiện full path.
__set_window_title() {
  local dir="${PWD/#$HOME/}"
  printf '\033]2;~%s\007' "$dir"
}
PROMPT_COMMAND="__set_window_title${PROMPT_COMMAND:+;$PROMPT_COMMAND}"

# ── Hàm tiện ích ────────────────────────────────────────────
mkcd() { mkdir -pv -- "$1" && cd -- "$1"; }

# Giải nén tự đoán định dạng
extract() {
  case "$1" in
    *.tar.bz2)   tar xjf "$1"  ;;
    *.tar.gz|*.tgz) tar xzf "$1" ;;
    *.tar.xz|*.txz) tar xJf "$1" ;;
    *.tar.zst)   tar --zstd -xf "$1" ;;
    *.tar)       tar xf "$1"  ;;
    *.7z)        7z x "$1"     ;;
    *.zip)       unzip "$1"    ;;
    *.rar)       7z x "$1"     ;;
    *.gz)        gunzip "$1"   ;;
    *) echo "extract: định dạng lạ: $1" >&2; return 1 ;;
  esac
}

# Nén theo thư mục
pack() { tar czf "${2:-${1##*/}.tar.gz}" "$1" && echo "→ ${2:-${1##*/}.tar.gz}"; }

# Sao lưu file trước khi sửa: cp config.json{,.bak}
bak() { cp -- "$1" "$1.bak" && echo "→ $1.bak"; }
