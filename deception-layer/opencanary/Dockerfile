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
RUN mkdir -p /etc/opencanary /var/log/canary /mnt/canary/backups /mnt/canary/admin

# Copy configuration files
COPY opencanary.conf /etc/opencanary/opencanary.conf
COPY opencanary-config.conf /etc/opencanary/opencanary-config.conf

# Create dummy certificates and files for HTTP/SMB
RUN openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
    -subj "/C=US/ST=State/L=City/O=HoneyPod/CN=honeypod.local" \
    -keyout /etc/opencanary/honeypot.key -out /etc/opencanary/honeypot.crt && \
    touch /mnt/canary/backups/database_2024.sql && \
    touch /mnt/canary/admin/credentials.txt

EXPOSE 21 22 23 80 443 445 3306 3389 5432 5900 9999

# Start OpenCanary using shell form to keep container alive
CMD opencanaryd --start && tail -f /dev/null
