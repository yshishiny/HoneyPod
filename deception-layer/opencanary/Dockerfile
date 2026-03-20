FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    python3-venv \
    sudo \
    build-essential \
    libssl-dev \
    libffi-dev \
    libpcap-dev \
    libnetfilter-queue-dev \
    smbclient \
    tcpdump \
    && rm -rf /var/lib/apt/lists/*

# Install OpenCanary
RUN pip3 install opencanary scapy pcapy-ng

# Create necessary directories
RUN mkdir -p /etc/opencanaryd /var/log/opencanary /mnt/canary/backups /mnt/canary/admin

# Copy the JSON configuration file to the correct path
COPY opencanary.json /etc/opencanaryd/opencanary.conf

# Create dummy certificates for HTTPS honeypot
RUN openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
    -subj "/C=US/ST=State/L=City/O=HoneyPod/CN=honeypod.local" \
    -keyout /etc/opencanaryd/honeypot.key -out /etc/opencanaryd/honeypot.crt && \
    touch /mnt/canary/backups/database_2024.sql && \
    touch /mnt/canary/admin/credentials.txt

EXPOSE 21 22 23 80 3306

# Run OpenCanary in the foreground
CMD ["/usr/local/bin/opencanaryd", "--dev"]
