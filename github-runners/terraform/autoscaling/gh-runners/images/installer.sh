#!/bin/bash -e
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

set +x
%{ if enable_debug_logging }
set -x
%{ endif }

# Detect the Linux distribution
if [ -f /etc/system-release ]; then
    # Amazon Linux
    pkg_manager="dnf"
    user_name="ec2-user"
else
    # Ubuntu
    pkg_manager="apt"
    user_name="ubuntu"
fi

# Update packages
if [ "$pkg_manager" == "dnf" ]; then
    $pkg_manager upgrade-minimal -y
else
    $pkg_manager update -y
fi

# Install docker
sudo cloud-init status --wait
sudo $pkg_manager -y update
sudo $pkg_manager -y install ca-certificates curl gnupg

if [ "$pkg_manager" == "dnf" ]; then
    sudo $pkg_manager config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    sudo $pkg_manager makecache
    sudo $pkg_manager -y install docker-ce docker-ce-cli containerd.io jq git unzip pkg-config openssl libssl3 libtool cmake @development-tools libudev-devel acl aria2 autoconf automake binutils bison brotli bzip2 coreutils dbus curl bind-utils dpkg dpkg-dev fakeroot file findutils flex google-noto-emoji-color-fonts gcc-c++ gcc gnupg2 iproute libc++-devel libc++abi-devel glibc-devel libcurl rsync ftp gcc-c++ gcc gnupg2 ImageMagick iproute iputils jq zlib-devel libc++-devel libc++abi-devel glibc-devel libcurl mesa-libgbm-devel GConf2-devel gsl-devel gtk3-devel file-devel ImageMagick-devel libsecret-devel sqlite-devel libtool libunwind libX11-devel libXss libsecret-devel libyaml-devel glibc-all-langpacks xz make mediainfo net-tools nmap-ncat openssh-clients p7zip p7zip-plugins parallel pass patchelf pigz pkg-config python3 rsync ShellCheck sqlite openssh-clients sshpass sudo swig tar telnet texinfo time tk tzdata unzip upx wget xorriso xorg-x11-server-Xvfb xz zip zsync
else
    sudo $pkg_manager -y install ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo $pkg_manager update -y
    sudo $pkg_manager install -y docker-ce docker-ce-cli containerd.io jq git unzip pkg-config openssl libtool cmake build-essential libudev-dev acl aria2 autoconf automake binutils bison brotli bzip2 coreutils dbus curl dnsutils dpkg dpkg-dev fakeroot file findutils flex fonts-noto-color-emoji g++ gcc gnupg2 iproute2 lib32z1 libc++-dev libc++abi-dev libc6-dev libcurl4 imagemagick iputils-ping libgbm-dev libgconf-2-4 libgsl-dev libgtk-3-0 libmagic-dev libmagickcore-dev libmagickwand-dev libsecret-1-dev libsqlite3-dev libunwind8 libxkbfile-dev libxss1 libyaml-dev locales lz4 m4 make mediainfo net-tools netcat openssh-client p7zip-full parallel patchelf pigz python-is-python3 rsync shellcheck sqlite3 ssh sshpass sudo swig tar texinfo time tk tzdata unzip upx wget xorriso xvfb xz-utils zip zsync
fi

sudo systemctl enable containerd.service
sudo service docker start
sudo usermod -a -G docker $user_name

if [ "$pkg_manager" == "dnf" ]; then
    $pkg_manager install -y amazon-cloudwatch-agent jq git
    $pkg_manager install -y --allowerasing curl
else
    curl -fsSL https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -o amazon-cloudwatch-agent.deb
    sudo dpkg -i amazon-cloudwatch-agent.deb
fi

sudo systemctl restart amazon-cloudwatch-agent
sudo curl -f https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip
unzip awscliv2.zip
sudo ./aws/install

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain nightly --default-host x86_64-unknown-linux-gnu --profile minimal -y --default-toolchain nightly -y --prefix /opt/hostedtoolcache/rust

# Append Rust's cargo bin directory to the global PATH for all users/sessions
echo 'export PATH=$PATH:$HOME/.cargo/bin' | sudo tee -a /etc/profile

# Apply the PATH change immediately
source /etc/profile
