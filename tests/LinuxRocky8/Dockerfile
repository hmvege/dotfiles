# Use Rocky 8 as the base image
FROM rockylinux:8

# Update and install necessary packages (curl, sudo, git)
RUN dnf -y update && \
    dnf -y install curl sudo git && \
    dnf clean all

# Create a non-root user for testing (optional, but recommended)
RUN useradd -ms /bin/bash developer && \
    echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER developer
WORKDIR /home/developer
ENV HOME=/home/developer

# Install Chezmoi into $HOME/.local/bin
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -t v2.49.1 -b "$HOME/.local/bin/"

# Update PATH so Chezmoi is found
ENV PATH=$HOME/.local/bin:$PATH

# Initialize and apply the dotfiles using Chezmoi
RUN chezmoi init --promptString "Enter GitHub mail for this machine=testmail" hmvege --branch "dotfile-updates-2024-linux"
RUN chezmoi apply -v

# Set default command to an interactive shell
CMD ["/bin/bash"]
