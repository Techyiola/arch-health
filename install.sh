#!/usr/bin/env bash
# =============================================================
#  arch-health — one-shot system health aliases for Arch Linux
#  Supports: Fish, Bash, Zsh
# =============================================================

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()  { echo -e "${CYAN}${BOLD}==> ${RESET}${BOLD}$*${RESET}"; }
ok()   { echo -e "${GREEN}✔  $*${RESET}"; }
warn() { echo -e "${YELLOW}⚠  $*${RESET}"; }
err()  { echo -e "${RED}✘  $*${RESET}"; exit 1; }

# ── Sanity check ─────────────────────────────────────────────
[[ -f /etc/arch-release ]] || err "This script is for Arch Linux only."

echo -e "\n${BOLD}  arch-health installer${RESET}"
echo    "  ─────────────────────────────────────────"
echo    "  Installs system health aliases for your shell(s)."
echo -e "  Detected OS: Arch Linux\n"

# ── 1. Install packages ───────────────────────────────────────
log "Installing required packages via pacman..."
sudo pacman -S --needed --noconfirm lm_sensors smartmontools pacman-contrib upower
ok "Packages installed."

# ── 2. Detect hardware paths ─────────────────────────────────
log "Detecting hardware paths..."

# Battery: BAT0 or BAT1
BAT_PATH=""
for b in /sys/class/power_supply/BAT{0,1}; do
  [[ -d "$b" ]] && { BAT_PATH="$b"; break; }
done
if [[ -n "$BAT_PATH" ]]; then
  BAT_NAME=$(basename "$BAT_PATH")
  ok "Battery found: $BAT_NAME"
else
  warn "No battery found — battery aliases will use BAT0 as default."
  BAT_NAME="BAT0"
fi

# Disk: sda or nvme0
DISK_DEV=""
for d in /dev/sda /dev/nvme0; do
  [[ -e "$d" ]] && { DISK_DEV="$d"; break; }
done
if [[ -n "$DISK_DEV" ]]; then
  ok "Primary disk: $DISK_DEV"
else
  warn "Could not detect primary disk — defaulting to /dev/sda."
  DISK_DEV="/dev/sda"
fi

# ── 3. Build alias blocks ─────────────────────────────────────
# POSIX-style (bash/zsh)
build_posix_aliases() {
  cat <<EOF

# ── arch-health aliases ────────────────────────────────────────
# Battery
alias bat='upower -i \$(upower -e | grep BAT)'
alias batdrain='cat /sys/class/power_supply/${BAT_NAME}/power_now'
alias bathealth='cat /sys/class/power_supply/${BAT_NAME}/energy_full /sys/class/power_supply/${BAT_NAME}/energy_full_design'

# Thermals & CPU
alias temps='sensors'
alias cputemp='cat /sys/class/thermal/thermal_zone*/temp'
alias cpufreq='grep MHz /proc/cpuinfo'

# Memory & cache
alias memcheck='free -h'
alias dropcache='sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"'
alias pkgcache='paccache -r'

# Disk & storage
alias diskhealth='sudo smartctl -H ${DISK_DEV}'
alias diskuse='df -h --exclude-type=tmpfs'
alias bigfiles='du -ah ~ | sort -rh | head -10'

# System & logs
alias syscheck='systemctl --failed'
alias errlogs='journalctl -p 3 -b'
alias netcheck='ping -c 4 1.1.1.1'

# All-in-one
alias syshealth='echo "=== Battery ===" && upower -i \$(upower -e | grep BAT) && echo "=== Temps ===" && sensors && echo "=== Memory ===" && free -h && echo "=== Disk ===" && df -h --exclude-type=tmpfs && echo "=== Failed units ===" && systemctl --failed'
# ───────────────────────────────────────────────────────────────
EOF
}

# Fish-style
build_fish_aliases() {
  cat <<EOF

# ── arch-health aliases ────────────────────────────────────────
# Battery
alias bat       "upower -i (upower -e | grep BAT)"
alias batdrain  "cat /sys/class/power_supply/${BAT_NAME}/power_now"
alias bathealth "cat /sys/class/power_supply/${BAT_NAME}/energy_full /sys/class/power_supply/${BAT_NAME}/energy_full_design"

# Thermals & CPU
alias temps   "sensors"
alias cputemp "cat /sys/class/thermal/thermal_zone*/temp"
alias cpufreq "grep MHz /proc/cpuinfo"

# Memory & cache
alias memcheck  "free -h"
alias dropcache "sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'"
alias pkgcache  "paccache -r"

# Disk & storage
alias diskhealth "sudo smartctl -H ${DISK_DEV}"
alias diskuse    "df -h --exclude-type=tmpfs"
alias bigfiles   "du -ah ~ | sort -rh | head -10"

# System & logs
alias syscheck "systemctl --failed"
alias errlogs  "journalctl -p 3 -b"
alias netcheck "ping -c 4 1.1.1.1"

# All-in-one
alias syshealth "echo '=== Battery ===' && upower -i (upower -e | grep BAT) && echo '=== Temps ===' && sensors && echo '=== Memory ===' && free -h && echo '=== Disk ===' && df -h --exclude-type=tmpfs && echo '=== Failed units ===' && systemctl --failed"
# ───────────────────────────────────────────────────────────────
EOF
}

# ── 4. Inject into shell configs ─────────────────────────────
MARKER="# ── arch-health aliases"
INJECTED=0

inject_posix() {
  local cfg="$1"
  if [[ -f "$cfg" ]]; then
    if grep -q "$MARKER" "$cfg"; then
      warn "$cfg already has arch-health aliases — skipping."
    else
      build_posix_aliases >> "$cfg"
      ok "Aliases added to $cfg"
      INJECTED=1
    fi
  fi
}

inject_fish() {
  local cfg="$HOME/.config/fish/config.fish"
  mkdir -p "$(dirname "$cfg")"
  touch "$cfg"
  if grep -q "$MARKER" "$cfg"; then
    warn "$cfg already has arch-health aliases — skipping."
  else
    build_fish_aliases >> "$cfg"
    ok "Aliases added to $cfg"
    INJECTED=1
  fi
}

log "Injecting aliases into shell config files..."

# Bash
inject_posix "$HOME/.bashrc"

# Zsh
inject_posix "$HOME/.zshrc"

# Fish
inject_fish

[[ $INJECTED -eq 0 ]] && warn "All config files already contained aliases. Nothing was changed."

# ── 5. Run sensors-detect ─────────────────────────────────────
log "Running sensors-detect (one-time lm_sensors setup)..."
echo -e "${YELLOW}  You may be prompted to answer questions — pressing Enter for all defaults is fine.${RESET}"
sudo sensors-detect --auto
ok "sensors-detect complete."

# ── 6. Done ───────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}  ✔ arch-health installed successfully!${RESET}"
echo    "  ─────────────────────────────────────────"
echo    "  Reload your shell to activate aliases:"
echo    ""
echo -e "    ${CYAN}Bash:${RESET}  source ~/.bashrc"
echo -e "    ${CYAN}Zsh:${RESET}   source ~/.zshrc"
echo -e "    ${CYAN}Fish:${RESET}  source ~/.config/fish/config.fish"
echo    ""
echo    "  Then run:  syshealth"
echo    ""
