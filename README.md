# 🛠️ Bug Bounty Recon Tools Installer

A fully automated **Bug Bounty Reconnaissance Tools Installer** for Linux (Ubuntu/Debian based).
This script installs and configures the most popular tools used in bug bounty and recon workflows — including Go-based, Python-based, and legacy tools — all in one go.

---

## 🚀 Features

* Automatic installation of:

  * **Go tools** like `subfinder`, `httpx`, `nuclei`, `ffuf`, `naabu`, and more.
  * **Python tools** using `pipx` such as `arjun`, `altdns`, `uro`, etc.
  * **Legacy tools** (`Sublist3r`, `dnscan`, `LinkFinder`).
* **Auto Go version detection** and upgrade to the latest release.
* **Safe execution** — script runs with error handling (no root required).
* Creates and preconfigures **Subfinder** and **Amass** config files.
* Prints a full **installation summary** and version verification at the end.

---

## 🧩 Requirements

* Ubuntu / Debian-based system
* Internet connection
* `sudo` privileges (will be used only when required)

---

## ⚙️ Installation

Clone the repository and run the installer script:

```bash
git clone https://github.com/0xsl4m/recon-tools-installer.git
cd recon-tools-installer
chmod +x install_recon_tools.sh
./install_recon_tools.sh
```

> 💡 Do **NOT** run the script as root (`sudo ./install-tools.sh` is not allowed).
> The script will ask for `sudo` permissions when needed.

---

## 🔑 API Keys Configuration

After installation, add your API keys to improve tool accuracy:

* **Subfinder config:** `~/.config/subfinder/provider-config.yaml`
* **Amass config:** `~/.config/amass/config.ini`

Example:

```yaml
shodan: ["YOUR_SHODAN_API_KEY"]
github: ["YOUR_GITHUB_TOKEN"]
virustotal: ["YOUR_VIRUSTOTAL_API_KEY"]
```

---

## 🧪 Quick Test

Run a few commands to verify tools were installed correctly:

```bash
subfinder -version
httpx -version
nuclei -version
pipx list
```

If any tool is missing, check the summary at the end of the script output for quick fixes.

---

## 📁 Paths

| Type                   | Path             |
| ---------------------- | ---------------- |
| Tools Directory        | `~/recon-tools/` |
| Go Binaries            | `~/go/bin/`      |
| Python (pipx) Binaries | `~/.local/bin/`  |

---

## 🧰 Included Tools

**Go-based:**
`subfinder`, `httpx`, `nuclei`, `dnsx`, `naabu`, `ffuf`, `assetfinder`, `katana`, `gau`, `hakrawler`, `gowitness`, `waybackurls`, `subzy`, `anew`, `unfurl`

**Python (pipx):**
`arjun`, `altdns`, `wafw00f`, `uro`

**Legacy:**
`Sublist3r`, `dnscan`, `LinkFinder`

---

## ⚠️ Notes

* If any tool fails, it can be manually reinstalled using `go install` or `pipx install`.
* Run `source ~/.bashrc` or restart your terminal after installation to update your PATH.
* Script tested on Ubuntu 22.04 and Debian 12.

---

## 📄 Version

**v3.6** — Added `libpcap-dev` fix for Naabu and improved legacy tool installation.
