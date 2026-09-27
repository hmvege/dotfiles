# syntax=docker/dockerfile:1
FROM rockylinux:8

# Prepare the base system only. Dotfiles are initialized and applied at runtime.
RUN dnf -y install ca-certificates curl git sudo && \
    dnf clean all

RUN groupadd --gid 1010 developer && \
    useradd --create-home --shell /bin/bash --uid 1010 --gid 1010 developer && \
    printf 'developer ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer

# Rocky stays on the compatibility version used by the existing setup.
RUN sh -c "$(curl -fsLS https://get.chezmoi.io)" -- \
    -t v2.49.1 -b /usr/local/bin

COPY .chezmoiroot /dotfiles/.chezmoiroot
COPY home/ /dotfiles/home/
RUN chmod -R a+rX /dotfiles

USER developer
WORKDIR /home/developer
ENV HOME=/home/developer

CMD ["/bin/bash"]
