#!/bin/bash
# ==========================================
# Bug Bounty Recon Tools Installer
# Part 1: Tools Installation & Configuration
# Version 3.6 - Added libpcap-dev (Fixes Naabu) & Refined Legacy Tools
# ==========================================
# set -e removed completely. We rely on if/else for continuity.
set -o pipefail # Ensures errors within pipelines are caught

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}
print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}
print_error() {
    echo -e "${RED}[✗]${NC} $1"
}
print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}
print_section() {
    echo -e "\n${PURPLE}========================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}========================================${NC}\n"
}
print_info() {
    echo -e "${CYAN}[ℹ]${NC} $1"
}

# Function to compare versions (e.g., is 1.21 < 1.24)
version_compare() {
    if [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" != "$2" ]; then
        return 0  # $1 < $2 (i.e., $1 is older/smaller)
    else
        return 1  # $1 >= $2
    fi
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Don't run this script as root/sudo. It will ask for sudo when needed."
    exit 1
fi

clear
echo -e "${PURPLE}"
cat << "EOF"
╔═══════════════════════════════════════════════════╗
║ Bug Bounty Tools Installer v3.6 (Final Fixes) 🛡️ ║
║ Part 1: Tools Installation & Config ║
╚═══════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
print_status "Starting tools installation process..."
sleep 2

# ==========================================
# 1. Update System & Install Dependencies (FIX: Added libpcap-dev)
# ==========================================
print_section "Step 1: System Update & Dependencies"
print_status "Updating package lists..."
sudo apt update -qq || print_error "Failed to update package lists, continuing..."
print_status "Installing essential dependencies (including libpcap-dev for Naabu/GoPcap)..."
# libpcap-dev is critical for Naabu compilation
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    git \
    wget \
    curl \
    build-essential \
    libssl-dev \
    libffi-dev \
    jq \
    unzip \
    dnsutils \
    net-tools \
    nmap \
    masscan \
    libpcap-dev 2>/dev/null || print_warning "Some dependencies may have failed, continuing..."
print_success "Dependencies installation attempted"

# ==========================================
# 2. Install/Upgrade Latest Go
# ==========================================
print_section "Step 2: Go Language Installation"

print_status "Fetching latest Go version and download page content from go.dev..."
DOWNLOAD_PAGE=$(curl -s https://go.dev/dl/) || {
    print_error "Failed to fetch Go download page, skipping Go installation..."
    LATEST_GO_STR=""
}

if [ -n "$DOWNLOAD_PAGE" ]; then
    LATEST_GO_STR=$(echo "$DOWNLOAD_PAGE" | grep -oP 'go[0-9]+\.[0-9]+(\.[0-9]+)?\.linux-amd64\.tar\.gz' | head -1 | sed 's/\.linux-amd64\.tar\.gz//')
fi

if [ -n "$LATEST_GO_STR" ]; then
    LATEST_GO_VERSION=$(echo "$LATEST_GO_STR" | sed 's/go//')
    GO_FILE="${LATEST_GO_STR}.linux-amd64.tar.gz"

    print_info "Latest Go version available: $LATEST_GO_VERSION"
    
    NEEDS_INSTALL=1
    
    if command -v go &> /dev/null; then
        CURRENT_GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        print_status "Detected current Go version: v$CURRENT_GO_VERSION"
        
        if version_compare "$CURRENT_GO_VERSION" "$LATEST_GO_VERSION"; then
            print_warning "Current Go v$CURRENT_GO_VERSION is outdated (latest: $LATEST_GO_VERSION). Upgrading..."
            sudo rm -rf /usr/local/go || print_error "Failed to remove old Go, continuing..."
        else
            print_success "Go is up-to-date: v$CURRENT_GO_VERSION"
            NEEDS_INSTALL=0
        fi
    fi
    
    # If no Go or outdated, install latest
    if [ "$NEEDS_INSTALL" -eq 1 ]; then
        print_status "Downloading Go $LATEST_GO_VERSION..."
        wget -q --show-progress "https://go.dev/dl/$GO_FILE" || {
            print_error "Download failed: $GO_FILE"
            print_warning "Skipping Go installation..."
        }
        
        if [ -f "$GO_FILE" ]; then
            # Verify checksum (FIXED LOGIC)
            print_status "Verifying checksum..."
            # Extract Hash from the downloaded page content
            EXPECTED_HASH=$(echo "$DOWNLOAD_PAGE" | grep -A 5 "$GO_FILE" | grep 'sha256' | sed -n 's/.*<tt>\([^<]*\)<\/tt>/\1/p' | head -1) || print_warning "Failed to fetch checksum from page, proceeding with caution..."
            
            if [ -n "$EXPECTED_HASH" ]; then
                FOUND_HASH=$(sha256sum "$GO_FILE" | awk '{print $1}')
                if [ "$FOUND_HASH" = "$EXPECTED_HASH" ]; then
                    print_success "Checksum verified"
                else
                    print_error "Checksum verification failed! Expected: $EXPECTED_HASH, Found: $FOUND_HASH"
                    print_warning "Download may be corrupted, but continuing with caution..."
                fi
            fi
            
            print_status "Installing Go $LATEST_GO_VERSION..."
            sudo rm -rf /usr/local/go || print_error "Failed to remove old Go, continuing..."
            sudo tar -C /usr/local -xzf "$GO_FILE" || print_error "Failed to extract Go, continuing..."
            rm "$GO_FILE" || true
            
            # Add Go to PATH permanently (if not already there)
            if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
                echo '' >> ~/.bashrc
                echo '# Go Language Configuration' >> ~/.bashrc
                echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
                echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc
                print_info "Go PATH added to ~/.bashrc"
            fi
            
            print_success "Go installation attempted: v$LATEST_GO_VERSION"
        fi
    fi
    # Set/Export PATH for current session regardless of install status
    export PATH=$PATH:/usr/local/go/bin
    export PATH=$PATH:$HOME/go/bin
else
    print_warning "Unable to determine latest Go version, skipping upgrade/installation..."
fi

# ==========================================
# 3. Install pipx (Python Tool Manager)
# ==========================================
print_section "Step 3: Installing pipx"
if ! command -v pipx &> /dev/null; then
    print_status "Installing pipx..."
    if sudo apt install -y pipx 2>/dev/null; then
        :
    else
        python3 -m pip install --user pipx || print_error "pipx install failed, continuing..."
    fi
    pipx ensurepath || true
    export PATH="$PATH:$HOME/.local/bin"
    
    if ! grep -q "$HOME/.local/bin" ~/.bashrc; then
        echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bashrc
        print_info "pipx PATH added to ~/.bashrc"
    fi
    
    print_success "pipx installation attempted"
else
    print_success "pipx already installed"
    export PATH="$PATH:$HOME/.local/bin"
fi

# ==========================================
# 4. Create Tools Directory Structure
# ==========================================
print_section "Step 4: Directory Setup"
TOOLS_DIR="$HOME/recon-tools"
BIN_DIR="$TOOLS_DIR/bin"
mkdir -p "$TOOLS_DIR" "$BIN_DIR" || print_error "Failed to create directories, continuing..."
print_success "Directory setup attempted at: $TOOLS_DIR"

# ==========================================
# 5. Install Go-Based Tools (Error Continuous)
# ==========================================
print_section "Step 5: Installing Go-Based Tools"
print_info "This may take several minutes depending on your internet speed..."

go_tools=(
    "github.com/tomnomnom/assetfinder@latest:AssetFinder:Subdomain Discovery"
    "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest:SubFinder:Subdomain Discovery"
    "github.com/owasp-amass/amass/v4/...@master:Amass:Subdomain Discovery"
    "github.com/projectdiscovery/httpx/cmd/httpx@latest:HTTPX:HTTP Probe"
    "github.com/projectdiscovery/dnsx/cmd/dnsx@latest:DNSX:DNS Toolkit"
    "github.com/ffuf/ffuf/v2@latest:FFUF:Web Fuzzer"
    "github.com/tomnomnom/waybackurls@latest:Waybackurls:Wayback URLs"
    "github.com/lc/gau/v2/cmd/gau@latest:GAU:Get All URLs"
    "github.com/hakluke/hakrawler@latest:Hakrawler:Web Crawler"
    "github.com/projectdiscovery/katana/cmd/katana@latest:Katana:Web Crawler"
    "github.com/PentestPad/subzy@latest:Subzy:Subdomain Takeover (Updated Path)" # Fixed path
    "github.com/sensepost/gowitness@latest:GoWitness:Screenshot Tool"
    "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest:Nuclei:Vulnerability Scanner"
    "github.com/tomnomnom/anew@latest:Anew:Append New Lines"
    "github.com/tomnomnom/unfurl@latest:Unfurl:URL Parser"
    "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest:Naabu:Port Scanner"
)

go_installed=0
go_failed=0
for tool_info in "${go_tools[@]}"; do
    IFS=':' read -r tool_path tool_name tool_desc <<< "$tool_info"
    print_status "Installing $tool_name ($tool_desc)..."
    
    if output=$(go install -v "$tool_path" 2>&1); then
        print_success "$tool_name installed"
        ((go_installed++))
    else
        print_error "$tool_name installation failed:"
        echo "$output" | head -5
        ((go_failed++))
    fi
done

# Update Nuclei templates
print_status "Updating Nuclei templates..."
nuclei -update-templates -silent 2>/dev/null && print_success "Nuclei templates updated" || print_warning "Nuclei templates update failed (will update on first run)"

# ==========================================
# 6. Install Python Tools via pipx
# ==========================================
print_section "Step 6: Installing Python Tools (pipx)"
print_info "Using pipx for isolated Python environments"

pipx_tools=(
    "py-altdns:altdns:DNS Permutation"
    "arjun:arjun:Parameter Discovery"
    "wafw00f:wafw00f:WAF Detection"
    "uro:uro:URL Deduplication"
)

pipx_installed=0
pipx_failed=0
for tool_info in "${pipx_tools[@]}"; do
    IFS=':' read -r package_name tool_name tool_desc <<< "$tool_info"
    print_status "Installing $tool_name ($tool_desc)..."
    
    if pipx list --short 2>/dev/null | grep -q "^$package_name"; then
        print_warning "$tool_name already installed"
        ((pipx_installed++))
    elif pipx install "$package_name" 2>/dev/null; then
        print_success "$tool_name installed via pipx"
        ((pipx_installed++))
    else
        print_error "$tool_name installation failed"
        ((pipx_failed++))
    fi
done

# ==========================================
# 7. Install Legacy Python Tools (Manual)
# ==========================================
print_section "Step 7: Installing Legacy Python Tools"
print_info "Using manual installation for tools without proper packaging"

cd "$TOOLS_DIR" || print_error "Failed to cd to $TOOLS_DIR, skipping legacy tools..."

legacy_installed=0
legacy_failed=0

# Sublist3r
print_status "Installing Sublist3r..."
if [ ! -d "$TOOLS_DIR/Sublist3r" ]; then
    git clone -q https://github.com/aboul3la/Sublist3r.git 2>/dev/null && {
        cd Sublist3r || true
        # FIX: Ensure requirements installation is handled for better logging
        pip3 install -q -r requirements.txt 2>/dev/null || print_warning "Sublist3r requirements failed/skipped"
        chmod +x sublist3r.py || true
        # Using /usr/local/bin for global access
        sudo ln -sf "$TOOLS_DIR/Sublist3r/sublist3r.py" /usr/local/bin/sublist3r 2>/dev/null && print_success "Sublist3r installed & symlinked" && ((legacy_installed++))
        cd "$TOOLS_DIR" || true
    } || {
        print_error "Sublist3r installation/clone failed"
        ((legacy_failed++))
    }
else
    print_warning "Sublist3r already exists"
    ((legacy_installed++))
fi

# dnscan
print_status "Installing dnscan..."
if [ ! -d "$TOOLS_DIR/dnscan" ]; then
    git clone -q https://github.com/rbsec/dnscan.git 2>/dev/null && {
        cd dnscan || true
        pip3 install -q -r requirements.txt 2>/dev/null || print_warning "dnscan requirements failed/skipped"
        chmod +x dnscan.py || true
        sudo ln -sf "$TOOLS_DIR/dnscan/dnscan.py" /usr/local/bin/dnscan 2>/dev/null && print_success "dnscan installed & symlinked" && ((legacy_installed++))
        cd "$TOOLS_DIR" || true
    } || {
        print_error "dnscan installation/clone failed"
        ((legacy_failed++))
    }
else
    print_warning "dnscan already exists"
    ((legacy_installed++))
fi

# LinkFinder
print_status "Installing LinkFinder..."
if [ ! -d "$TOOLS_DIR/LinkFinder" ]; then
    git clone -q https://github.com/GerbenJavado/LinkFinder.git 2>/dev/null && {
        cd LinkFinder || true
        pip3 install -q -r requirements.txt 2>/dev/null || print_warning "LinkFinder requirements failed/skipped"
        # The output showed 'setup.py install' was successful, so we keep this.
        python3 setup.py install --user 2>/dev/null || print_warning "LinkFinder setup failed (try using linkfinder.py directly)"
        chmod +x linkfinder.py || true
        sudo ln -sf "$TOOLS_DIR/LinkFinder/linkfinder.py" /usr/local/bin/linkfinder 2>/dev/null && print_success "LinkFinder installed & symlinked" && ((legacy_installed++))
        cd "$TOOLS_DIR" || true
    } || {
        print_error "LinkFinder installation/clone failed"
        ((legacy_failed++))
    }
else
    print_warning "LinkFinder already exists"
    ((legacy_installed++))
fi

# Go back to home directory
cd "$HOME" || true

# ==========================================
# 8. Create Configuration Files
# ==========================================
print_section "Step 8: Creating Configuration Files"

# Subfinder config
mkdir -p ~/.config/subfinder || print_warning "Failed to create subfinder config dir"
if [ ! -f ~/.config/subfinder/provider-config.yaml ]; then
    cat > ~/.config/subfinder/provider-config.yaml << 'EOFCONFIG' || print_error "Failed to create subfinder config"
# Subfinder Provider Configuration
# Add your API keys here for better results
# Shodan - https://account.shodan.io/
# shodan: ["YOUR_SHODAN_API_KEY"]
# Censys - https://censys.io/account/api
# censys: ["YOUR_CENSYS_API_ID:YOUR_CENSYS_API_SECRET"]
# GitHub - https://github.com/settings/tokens
# github: ["YOUR_GITHUB_TOKEN"]
# VirusTotal - https://www.virustotal.com/gui/user/YOUR_USERNAME/apikey
# virustotal: ["YOUR_VIRUSTOTAL_API_KEY"]
# SecurityTrails - https://securitytrails.com/app/account/credentials
# securitytrails: ["YOUR_SECURITYTRAILS_API_KEY"]
# Passivetotal - https://community.riskiq.com/settings
# passivetotal: ["YOUR_PASSIVETOTAL_USERNAME:YOUR_PASSIVETOTAL_API_KEY"]
# BinaryEdge - https://app.binaryedge.io/account/api
# binaryedge: ["YOUR_BINARYEDGE_API_KEY"]
# FullHunt - https://fullhunt.io/dashboard
# fullhunt: ["YOUR_FULLHUNT_API_KEY"]
EOFCONFIG
    print_success "Subfinder config created at ~/.config/subfinder/"
else
    print_warning "Subfinder config already exists"
fi

# Amass config
mkdir -p ~/.config/amass || print_warning "Failed to create amass config dir"
if [ ! -f ~/.config/amass/config.ini ]; then
    cat > ~/.config/amass/config.ini << 'EOFCONFIG' || print_error "Failed to create amass config"
# Amass Configuration File
# Add your API keys here for better results
# [data_sources.AlienVault]
# [data_sources.AlienVault.Credentials]
# apikey = YOUR_ALIENVAULT_API_KEY
# [data_sources.BinaryEdge]
# [data_sources.BinaryEdge.Credentials]
# apikey = YOUR_BINARYEDGE_API_KEY
# [data_sources.Shodan]
# [data_sources.Shodan.Credentials]
# apikey = YOUR_SHODAN_API_KEY
# [data_sources.SecurityTrails]
# [data_sources.SecurityTrails.Credentials]
# apikey = YOUR_SECURITYTRAILS_API_KEY
# [data_sources.VirusTotal]
# [data_sources.VirusTotal.Credentials]
# apikey = YOUR_VIRUSTOTAL_API_KEY
EOFCONFIG
    print_success "Amass config created at ~/.config/amass/"
else
    print_warning "Amass config already exists"
fi

# ==========================================
# 9. Verify Installation
# ==========================================
print_section "Step 9: Verification & Version Check"

tools_to_verify=(
    "assetfinder:Subdomain Discovery"
    "subfinder:Subdomain Discovery"
    "amass:Subdomain Discovery"
    "httpx:HTTP Probe"
    "dnsx:DNS Toolkit"
    "ffuf:Web Fuzzer"
    "waybackurls:Wayback URLs"
    "gau:Get All URLs"
    "hakrawler:Web Crawler"
    "katana:Web Crawler"
    "subzy:Subdomain Takeover"
    "gowitness:Screenshot Tool"
    "nuclei:Vulnerability Scanner"
    "naabu:Port Scanner"
    "anew:Append New"
    "unfurl:URL Parser"
    "uro:URL Deduplication"
    "altdns:DNS Permutation"
    "arjun:Parameter Discovery"
    "wafw00f:WAF Detection"
    "sublist3r:Subdomain Discovery (Legacy)"
    "dnscan:DNS Scanner (Legacy)"
    "linkfinder:Link Discovery (Legacy)"
)

installed_count=0
failed_tools=()
echo -e "${CYAN}Checking installed tools...${NC}\n"
for tool_info in "${tools_to_verify[@]}"; do
    IFS=':' read -r tool tool_desc <<< "$tool_info"
    if command -v "$tool" &> /dev/null; then
        print_success "$tool ($tool_desc)"
        ((installed_count++))
    else
        # Special check for legacy tools that might only be callable by their full path
        if [[ "$tool_desc" =~ Legacy ]] && [ -f "$TOOLS_DIR/${tool^}/${tool}.py" ]; then
             print_warning "$tool is not in PATH, but file exists in $TOOLS_DIR/${tool^}"
             ((installed_count++))
        else
            print_error "$tool is NOT found"
            failed_tools+=("$tool")
        fi
    fi
done

# ==========================================
# 10. Final Summary
# ==========================================
print_section "Tools Installation Complete! 🎉"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN} INSTALLATION SUMMARY${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo -e "${CYAN}📊 Statistics:${NC}"
echo -e " Go Tools: ${GREEN}$go_installed installed${NC} ${RED}$go_failed failed${NC}"
echo -e " pipx Tools: ${GREEN}$pipx_installed installed${NC} ${RED}$pipx_failed failed${NC}"
echo -e " Legacy Tools: ${GREEN}$legacy_installed installed${NC} ${RED}$legacy_failed failed${NC}"
echo -e " ${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e " Total: ${GREEN}$installed_count/${#tools_to_verify[@]} tools verified${NC}"
if [ ${#failed_tools[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}⚠ Failed tools or tools not found in PATH: ${failed_tools[*]}${NC}"
    echo -e "${YELLOW}→ You can try installing them manually later${NC}"
fi
echo ""
echo -e "${BLUE}📁 Installation Paths:${NC}"
echo -e " Tools Directory: ${GREEN}$TOOLS_DIR${NC}"
echo -e " Go Binaries: ${GREEN}$HOME/go/bin${NC}"
echo -e " pipx Tools: ${GREEN}$HOME/.local/bin${NC}"
echo ""
echo -e "${BLUE}🔧 Configuration Files Created:${NC}"
echo -e " Subfinder: ${GREEN}~/.config/subfinder/provider-config.yaml${NC}"
echo -e " Amass: ${GREEN}~/.config/amass/config.ini${NC}"
echo -e " ${YELLOW}→ Edit these files to add your API keys${NC}"
echo ""
echo -e "${BLUE}🔑 API Keys (Optional but Recommended):${NC}"
echo -e " Adding API keys will significantly improve results!"
echo -e " ${CYAN}Shodan:${NC} https://account.shodan.io/"
echo -e " ${CYAN}VirusTotal:${NC} https://www.virustotal.com/gui/user/YOUR_USERNAME/apikey"
echo -e " ${CYAN}GitHub:${NC} https://github.com/settings/tokens"
echo -e " ${CYAN}SecurityTrails:${NC} https://securitytrails.com/app/account/credentials"
echo ""
echo -e "${RED}⚠ IMPORTANT - Update PATH:${NC}"
echo -e " Run one of these commands:"
echo -e " ${GREEN}source ~/.bashrc${NC}"
echo -e " ${GREEN}exec bash${NC}"
echo -e " Or ${GREEN}restart your terminal${NC}"
echo ""
echo -e "${BLUE}💡 Quick Test:${NC}"
echo -e " ${GREEN}subfinder -version${NC}"
echo -e " ${GREEN}httpx -version${NC}"
echo -e " ${GREEN}nuclei -version${NC}"
echo -e " ${GREEN}pipx list${NC}"
echo ""
