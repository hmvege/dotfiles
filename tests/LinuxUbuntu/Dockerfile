# syntax=docker/dockerfile:1
ARG UBUNTU_VERSION=24.04
FROM ubuntu:${UBUNTU_VERSION}

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Oslo

# Prepare the base system only. Dotfiles are initialized and applied at runtime.
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl git sudo tzdata && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 1010 developer && \
    useradd --create-home --shell /bin/bash --uid 1010 --gid 1010 developer && \
    printf 'developer ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    groupadd --gid 1020 nosudo && \
    useradd --create-home --shell /bin/bash --uid 1020 --gid 1020 nosudo

# A system-wide binary lets the same image test developer, root, and no-sudo users.
RUN sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b /usr/local/bin

COPY .chezmoiroot /dotfiles/.chezmoiroot
COPY home/ /dotfiles/home/
RUN chmod -R a+rX /dotfiles

USER developer
WORKDIR /home/developer
ENV HOME=/home/developer

CMD ["/bin/bash"]
