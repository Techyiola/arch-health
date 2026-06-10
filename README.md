# arch-health

One-shot installer that sets up system health monitoring aliases on Arch Linux.

Supports **Fish**, **Bash**, and **Zsh**.

---

## What it does

1. Installs required packages (`lm_sensors`, `smartmontools`, `pacman-contrib`, `upower`)
2. Auto-detects your battery (`BAT0` / `BAT1`) and primary disk (`/dev/sda` / `/dev/nvme0`)
3. Injects health aliases into all detected shell configs
4. Runs `sensors-detect` for one-time thermal sensor setup

---

## Install

```bash
git clone https://github.com/your-username/arch-health.git
cd arch-health
chmod +x install.sh
./install.sh
```

Then reload your shell:

```bash
# Bash
source ~/.bashrc

# Zsh
source ~/.zshrc

# Fish
source ~/.config/fish/config.fish
```

---

## Aliases

### Battery
| Alias | What it does |
|-------|--------------|
| `bat` | Health, capacity & charge cycle count |
| `batdrain` | Live energy drain rate (µW) |
| `bathealth` | Design vs current full-charge capacity |

### Thermals & CPU
| Alias | What it does |
|-------|--------------|
| `temps` | All sensor temperatures |
| `cputemp` | Quick CPU package temp |
| `cpufreq` | Current per-core frequency |

### Memory & Cache
| Alias | What it does |
|-------|--------------|
| `memcheck` | RAM usage (human readable) |
| `dropcache` | Drop page/slab/inode cache |
| `pkgcache` | Clean pacman package cache |

### Disk & Storage
| Alias | What it does |
|-------|--------------|
| `diskhealth` | SMART health report |
| `diskuse` | Disk usage per partition |
| `bigfiles` | Top 10 largest files in home dir |

### System & Logs
| Alias | What it does |
|-------|--------------|
| `syscheck` | Failed systemd units |
| `errlogs` | Recent error/critical journal logs |
| `netcheck` | Quick ping latency test |

### All-in-one
| Alias | What it does |
|-------|--------------|
| `syshealth` | Runs all checks in one command |

---

## Requirements

- Arch Linux
- `sudo` access
- One of: Fish, Bash, or Zsh

---

## Notes

- Safe to re-run — aliases are only added once (duplicate detection built in)
- If your battery is `BAT1` or disk is `/dev/nvme0`, the script detects it automatically
- `dropcache` and `diskhealth` require sudo; all other aliases run as normal user
