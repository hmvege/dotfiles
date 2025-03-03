# Use a build argument to choose the Ubuntu version (default: 20.04)
ARG UBUNTU_VERSION=20.04
FROM ubuntu:${UBUNTU_VERSION}

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ="Europe/Oslo"

# Install basic dependencies
RUN apt-get update && \
    apt-get install -y curl sudo git xauth x11-apps tzdata && \
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

# Install Chezmoi into $HOME/.local/bin
RUN cd $HOME && sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin/"

# Update PATH so Chezmoi is found
ENV PATH=$HOME/.local/bin:$PATH

# Initialize and apply the dotfiles using Chezmoi
ARG GIT_BRANCH=master
RUN cd $HOME && chezmoi init --promptString "Enter GitHub mail for this machine=testmail" hmvege --branch "$GIT_BRANCH"

# Set default command to an interactive shell (or override with test image)
CMD ["/bin/bash"]
