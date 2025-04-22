# Use a build argument to choose the Ubuntu version (default: 20.04)
ARG UBUNTU_VERSION=20.04
FROM ubuntu:${UBUNTU_VERSION}

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ="Europe/Oslo"

# Install basic dependencies
RUN apt-get update && \
    apt-get install -y curl git sudo tzdata xauth x11-apps && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user for testing, handling existing GID conflicts (GitHub action ubuntu docker images has 1000)
RUN groupadd -g 1010 developer && \
    useradd -m -s /bin/bash -u 1010 -g 1010 developer && \
    echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Ensure the home directory has correct ownership
RUN chown -R developer:developer /home/developer

# Set the user first, then switch working directory explicitly
USER developer
WORKDIR /home/developer
ENV HOME=/home/developer

# Determine Ubuntu version and install correct Chezmoi version into $HOME/.local/bin
# Ubuntu 20.04 and previously require an older Chezmoi version in order to work
# due to missing GLIBC library.
RUN UBUNTU_VERSION=$(awk -F= '/^VERSION_ID/ { print $2 }' /etc/os-release | tr -d '"') && \
    if [ "$(echo "$UBUNTU_VERSION" | cut -d. -f1)" -ge 22 ]; then \
    CHEZMOI_VERSION="latest"; \
    else \
    CHEZMOI_VERSION="v2.49.1"; \
    fi && \
    cd $HOME && sh -c "$(curl -fsLS get.chezmoi.io)" -- -t "$CHEZMOI_VERSION" -b "$HOME/.local/bin/"

# Update PATH so Chezmoi is found
ENV PATH=$HOME/.local/bin:$PATH

# Initialize and apply the dotfiles using Chezmoi
ARG GIT_BRANCH=master
RUN cd $HOME && chezmoi init \
    --promptString "Enter GitHub mail for this machine=testmail@example.com" \
    --promptBool "Do you want a minimal (lite) setup (y/n)=n" \
    --promptBool "Install GUI tools (y/n)=n" \
    --branch "$GIT_BRANCH" hmvege

# Set default command to an interactive shell (or override with test image)
CMD ["/bin/bash"]
