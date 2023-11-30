FROM ubuntu:20.04

# Avoid interaction with tzdata
ARG DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y \
    git \
    curl \
    sudo \
    # any other software that your dotfiles configure
    && rm -rf /var/lib/apt/lists/*

# For installing VSCode and snap
RUN apt-get update && apt-get install -y snapd

# Create a non-root user
RUN useradd -m testuser && echo "testuser:testuser" | chpasswd && adduser testuser sudo

# Switch to the new user
USER testuser
WORKDIR /home/testuser
