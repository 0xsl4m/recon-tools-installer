#!/bin/bash

# ==========================================
# Recon Tools Full Installer for WSL/Linux
# Author: Islam
# ==========================================

set -e

TOOLS_DIR="$HOME/tools"
LOCAL_BIN="$HOME/.local/bin"
BASHRC="$HOME/.bashrc"

mkdir -p "$TOOLS_DIR"
mkdir -p "$LOCAL_BIN"

echo "[+] Starting installation..."

# ==========================================
# Helper Functions
# ==========================================

add_to_bashrc_if_missing() {
    local LINE="$1"

    if ! grep -Fxq "$LINE" "$BASHRC"; then
        echo "$LINE" >> "$BASHRC"
        echo "[+] Added to .bashrc: $LINE"
    else
        echo "[=] Already exists in .bashrc"
    fi
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ==========================================
# Update System Packages
# ==========================================

echo "[+] Updating apt packages..."
sudo apt update

# ==========================================
# Install Basic Dependencies
# ==========================================

echo "[+] Installing base dependencies..."

sudo apt install -y \
    git \
    curl \
    wget \
    unzip \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    ruby-full \
    parallel \
    brotli \
    xxd \
    docker.io \
    npm

# ==========================================
# Install NVM + NodeJS
# ==========================================

if [ ! -d "$HOME/.nvm" ]; then
    echo "[+] Installing NVM..."

    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

export NVM_DIR="$HOME/.nvm"

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

echo "[+] Installing latest NodeJS LTS..."

nvm install --lts
nvm use --lts

# ==========================================
# Add PATH only if missing
# ==========================================

add_to_bashrc_if_missing 'export PATH="$HOME/.local/bin:$PATH"'
add_to_bashrc_if_missing 'export PATH=$PATH:/usr/local/go/bin'
add_to_bashrc_if_missing 'export PATH=$PATH:$HOME/go/bin'

export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:/usr/local/go/bin"
export PATH="$PATH:$HOME/go/bin"

# ==========================================
# Install Go Tools
# ==========================================

echo "[+] Installing Go tools..."

go install github.com/projectdiscovery/alterx/cmd/alterx@latest
go install github.com/d3mondev/puredns/v2@latest
go install -v github.com/PentestPad/subzy@latest
go install -v github.com/sa7mon/s3scanner@latest
go install -v github.com/tomnomnom/qsreplace@latest
go install github.com/tomnomnom/gf@latest
go install -v github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest
go install github.com/003random/getJS/v2@latest
go install github.com/lc/subjs@latest
go install github.com/cc1a2b/jshunter@latest
go install github.com/jaeles-project/gospider@latest
go install -v github.com/projectdiscovery/katana/cmd/katana@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/tomnomnom/waybackurls@latest

# ==========================================
# Install gf patterns
# ==========================================

echo "[+] Installing gf patterns..."

mkdir -p "$HOME/.gf"

GF_PATH=$(find "$HOME/go/pkg/mod/" -type d -path "*github.com/tomnomnom/gf@*" | head -n 1)

if [ -n "$GF_PATH" ]; then

    add_to_bashrc_if_missing "source \"$GF_PATH/gf-completion.bash\""

    cp -r "$GF_PATH/examples/"* "$HOME/.gf/" 2>/dev/null || true
fi

if [ ! -d "$TOOLS_DIR/Gf-Patterns" ]; then
    cd "$TOOLS_DIR"
    git clone https://github.com/1ndianl33t/Gf-Patterns
fi

cp "$TOOLS_DIR/Gf-Patterns/"*.json "$HOME/.gf/" 2>/dev/null || true

# ==========================================
# Install altdns
# ==========================================

echo "[+] Installing altdns..."

if [ ! -d "$TOOLS_DIR/altdns" ]; then
    cd "$TOOLS_DIR"
    git clone https://github.com/infosec-au/altdns.git
fi

cd "$TOOLS_DIR/altdns"

python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip
pip install tldextract==2.2.0
pip install .

deactivate

sudo tee /usr/local/bin/altdns > /dev/null << EOF
#!/bin/bash
"$TOOLS_DIR/altdns/venv/bin/altdns" "\$@"
EOF

sudo chmod +x /usr/local/bin/altdns

# ==========================================
# Install massdns
# ==========================================

echo "[+] Installing massdns..."

if [ ! -d "$TOOLS_DIR/massdns" ]; then
    cd "$TOOLS_DIR"
    git clone https://github.com/blechschmidt/massdns.git
fi

cd "$TOOLS_DIR/massdns"

make

sudo cp bin/massdns /usr/local/bin/

# ==========================================
# Install webscreenshot
# ==========================================

echo "[+] Installing webscreenshot..."

pipx install webscreenshot || true

# ==========================================
# Install dirsearch
# ==========================================

echo "[+] Installing dirsearch..."

if [ ! -d "$TOOLS_DIR/dirsearch" ]; then
    cd "$TOOLS_DIR"
    git clone https://github.com/maurosoria/dirsearch.git --depth 1
fi

cd "$TOOLS_DIR/dirsearch"

python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip
pip install -r requirements.txt

deactivate

sudo tee /usr/local/bin/dirsearch > /dev/null << EOF
#!/bin/bash
"$TOOLS_DIR/dirsearch/venv/bin/python3" "$TOOLS_DIR/dirsearch/dirsearch.py" "\$@"
EOF

sudo chmod +x /usr/local/bin/dirsearch

# ==========================================
# Install CeWL
# ==========================================

echo "[+] Installing CeWL..."

if [ ! -d "$TOOLS_DIR/CeWL" ]; then
    cd "$TOOLS_DIR"
    git clone https://github.com/digininja/CeWL.git
fi

cd "$TOOLS_DIR/CeWL"

sudo gem install bundler

bundle config set path 'vendor/bundle'
bundle install

sudo tee /usr/local/bin/cewl > /dev/null << EOF
#!/bin/bash

CEWL_DIR="$TOOLS_DIR/CeWL"

cd "\$CEWL_DIR" || exit 1

bundle exec ruby cewl.rb "\$@"
EOF

sudo chmod +x /usr/local/bin/cewl

# ==========================================
# Install LinkFinder
# ==========================================

echo "[+] Installing LinkFinder..."

if [ ! -d "$TOOLS_DIR/LinkFinder" ]; then
    cd "$TOOLS_DIR"
    git clone https://github.com/GerbenJavado/LinkFinder.git
fi

cd "$TOOLS_DIR/LinkFinder"

python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip
pip install -r requirements.txt

deactivate

tee "$LOCAL_BIN/linkfinder" > /dev/null << EOF
#!/bin/bash

LINKFINDER_DIR="$TOOLS_DIR/LinkFinder"
VENV_PYTHON="\$LINKFINDER_DIR/venv/bin/python3"

"\$VENV_PYTHON" "\$LINKFINDER_DIR/linkfinder.py" "\$@"
EOF

chmod +x "$LOCAL_BIN/linkfinder"

# ==========================================
# Install SecretFinder
# ==========================================

echo "[+] Installing SecretFinder..."

if [ ! -d "$TOOLS_DIR/SecretFinder" ]; then
    cd "$TOOLS_DIR"
    git clone https://github.com/m4ll0k/SecretFinder.git
fi

cd "$TOOLS_DIR/SecretFinder"

python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip
pip install -r requirements.txt

deactivate

sudo tee /usr/local/bin/secretfinder > /dev/null << EOF
#!/bin/bash
"$TOOLS_DIR/SecretFinder/venv/bin/python3" "$TOOLS_DIR/SecretFinder/SecretFinder.py" "\$@"
EOF

sudo chmod +x /usr/local/bin/secretfinder

# ==========================================
# Install js-snitch
# ==========================================

echo "[+] Installing js-snitch..."

if [ ! -d "$TOOLS_DIR/js-snitch" ]; then
    cd "$TOOLS_DIR"
    git clone https://github.com/vavkamil/js-snitch.git
fi

cd "$TOOLS_DIR/js-snitch"

python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip
pip install -r requirements.txt

deactivate

sudo tee /usr/local/bin/js-snitch > /dev/null << EOF
#!/bin/bash
"$TOOLS_DIR/js-snitch/venv/bin/python3" "$TOOLS_DIR/js-snitch/js_snitch.py" "\$@"
EOF

sudo chmod +x /usr/local/bin/js-snitch

# ==========================================
# Install xnLinkFinder
# ==========================================

echo "[+] Installing xnLinkFinder..."

mkdir -p "$TOOLS_DIR/xnLinkFinder"

cd "$TOOLS_DIR/xnLinkFinder"

python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip
pip install xnLinkFinder

deactivate

sudo tee /usr/local/bin/xnLinkFinder > /dev/null << EOF
#!/bin/bash
"$TOOLS_DIR/xnLinkFinder/venv/bin/xnLinkFinder" "\$@"
EOF

sudo chmod +x /usr/local/bin/xnLinkFinder

# ==========================================
# Install Feroxbuster
# ==========================================

echo "[+] Installing feroxbuster..."

cd "$TOOLS_DIR"

wget -q https://github.com/epi052/feroxbuster/releases/latest/download/x86_64-linux-feroxbuster.zip

unzip -o x86_64-linux-feroxbuster.zip

chmod +x feroxbuster

sudo mv feroxbuster /usr/local/bin/

rm -f x86_64-linux-feroxbuster.zip

# ==========================================
# Install theHarvester
# ==========================================

echo "[+] Installing theHarvester..."

if [ ! -d "$TOOLS_DIR/theHarvester" ]; then
    cd "$TOOLS_DIR"
    git clone https://github.com/laramies/theHarvester.git --depth 1
fi

cd "$TOOLS_DIR/theHarvester"

python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip
pip install wheel
pip install .

deactivate

sudo tee /usr/local/bin/theHarvester > /dev/null << EOF
#!/usr/bin/env bash
"$TOOLS_DIR/theHarvester/venv/bin/theHarvester" "\$@"
EOF

sudo chmod +x /usr/local/bin/theHarvester

# ==========================================
# Install jwt_tool
# ==========================================

echo "[+] Installing jwt_tool..."

if [ ! -d "$TOOLS_DIR/jwt_tool" ]; then
    cd "$TOOLS_DIR"
    git clone https://github.com/ticarpi/jwt_tool.git --depth 1
fi

cd "$TOOLS_DIR/jwt_tool"

python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip
pip install -r requirements.txt

deactivate

sudo tee /usr/local/bin/jwt_tool > /dev/null << EOF
#!/bin/bash
"$TOOLS_DIR/jwt_tool/venv/bin/python3" "$TOOLS_DIR/jwt_tool/jwt_tool.py" "\$@"
EOF

sudo chmod +x /usr/local/bin/jwt_tool

# ==========================================
# Install SQLMap
# ==========================================

echo "[+] Installing SQLMap..."

if [ ! -d "$TOOLS_DIR/sqlmap-dev" ]; then
    cd "$TOOLS_DIR"
    git clone --depth 1 https://github.com/sqlmapproject/sqlmap.git sqlmap-dev
fi

add_to_bashrc_if_missing "alias sqlmap='python3 \$HOME/tools/sqlmap-dev/sqlmap.py'"

# ==========================================
# Install Semgrep
# ==========================================

echo "[+] Installing Semgrep..."

mkdir -p "$TOOLS_DIR/semgrep"

cd "$TOOLS_DIR/semgrep"

python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip
pip install semgrep

deactivate

sudo tee /usr/local/bin/semgrep > /dev/null << EOF
#!/bin/bash
"$TOOLS_DIR/semgrep/venv/bin/semgrep" "\$@"
EOF

sudo chmod +x /usr/local/bin/semgrep

# ==========================================
# Install Ghauri
# ==========================================

echo "[+] Installing Ghauri..."

if [ ! -d "$TOOLS_DIR/ghauri" ]; then
    cd "$TOOLS_DIR"
    git clone https://github.com/r0oth3x49/ghauri.git
fi

cd "$TOOLS_DIR/ghauri"

python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip
pip install .

deactivate

sudo tee /usr/local/bin/ghauri > /dev/null << EOF
#!/bin/bash
"$TOOLS_DIR/ghauri/venv/bin/ghauri" "\$@"
EOF

sudo chmod +x /usr/local/bin/ghauri

# ==========================================
# Install git-dumper
# ==========================================

echo "[+] Installing git-dumper..."

mkdir -p "$TOOLS_DIR/git-dumper"

cd "$TOOLS_DIR/git-dumper"

python3 -m venv venv
source venv/bin/activate

pip install --upgrade pip
pip install git-dumper

deactivate

sudo tee /usr/local/bin/git-dumper > /dev/null << EOF
#!/bin/bash
"$TOOLS_DIR/git-dumper/venv/bin/git-dumper" "\$@"
EOF

sudo chmod +x /usr/local/bin/git-dumper

# ==========================================
# Install JS Tools
# ==========================================

echo "[+] Installing JS tools..."

npm install -g js-beautify
npm install -g retire

# ==========================================
# Install wafw00f
# ==========================================

echo "[+] Installing wafw00f..."

pip3 install --user wafw00f

# ==========================================
# Install trufflehog
# ==========================================

echo "[+] Installing trufflehog..."

go install github.com/trufflesecurity/trufflehog@latest

# ==========================================
# Final Message
# ==========================================

echo
echo "[+] Installation completed successfully!"
echo
echo "[+] Reload shell:"
echo "source ~/.bashrc"
echo
echo "[+] Verify tools:"
echo "check-tools.sh"
echo
