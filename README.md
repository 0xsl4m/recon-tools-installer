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

## Troubleshooting: If `dnscan` or `Sublist3r` fail to run

If you run into problems running `dnscan` or `Sublist3r` (missing modules, CRLF/shebang issues, DNS resolver errors, etc.), follow these steps in order. Each command includes a short explanation.

> **Note:** prefer running `python3` explicitly and use a virtual environment to install Python libs if possible (see step 6).

```bash
# 1) Update package lists
sudo apt update

# 2) Install basic utilities (pip, venv helper and dos2unix for CRLF fix)
sudo apt install -y python3-pip python3-venv dos2unix

# 3) Install dnspython from the distro (resolves "No module named 'dns'")
sudo apt install -y python3-dnspython

# (Optional) Create a compatibility symlink if some scripts call `python` instead of `python3`.
# Use only if you prefer calling `python` directly:
sudo ln -s /usr/bin/python3 /usr/bin/python

# 4) Fix Windows CRLF line endings in your scripts (very common if edited on Windows)
# Run in your scripts directory:
dos2unix *.sh

# 5) Make sure scripts are executable and create the target output folder
chmod +x ~/scripts/*.sh
mkdir -p ~/scripts/target

# 6) (Recommended) Create and use a virtual environment, then install Sublist3r requirements
python3 -m venv ~/venvs/recon
source ~/venvs/recon/bin/activate
pip install --upgrade pip
# If Sublist3r has a requirements.txt:
pip install -r ~/tools/Sublist3r/requirements.txt
# Run Sublist3r inside the venv:
python ~/tools/Sublist3r/sublist3r.py -d example.com -v -o ~/scripts/target/domains.txt
# Deactivate venv when done
deactivate

# 7) If a tool complains about DNS resolver (dnscan "No valid DNS resolver"), specify a public resolver:
python3 ~/tools/dnscan/dnscan.py -d example.com \
  -R 1.1.1.1

# 8) Quick checks
# Verify dnspython is importable by python3:
python3 -c "import dns; print('dnspython OK', getattr(dns,'__version__','no-version'))"

# Check current system resolver (useful if dnscan refuses system resolver)
cat /etc/resolv.conf
```

---

## ⚠️ Notes

* If any tool fails, it can be manually reinstalled using `go install` or `pipx install`.
* Run `source ~/.bashrc` or restart your terminal after installation to update your PATH.
* Script tested on Ubuntu 22.04 and Debian 12.

---

## 📄 Version

**v3.6** — Added `libpcap-dev` fix for Naabu and improved legacy tool installation.
