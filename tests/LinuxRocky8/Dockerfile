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
ARG GIT_BRANCH=master
RUN cd $HOME && chezmoi init \
    --promptString "Enter GitHub mail for this machine=testmail@example.com" \
    --promptBool "Do you want a minimal (lite) setup?=true" \
    --promptBool "Install GUI tools? (auto-detected GUI: true)=false" \
    --branch "$GIT_BRANCH" hmvege

# Set default command to an interactive shell
CMD ["/bin/bash"]
