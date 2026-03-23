FROM python:3.11-slim-bookworm

RUN apt-get update && apt-get install -y \
    git libssl-dev libffi-dev build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -d /cowrie cowrie

WORKDIR /cowrie

RUN git clone --depth 1 https://github.com/cowrie/cowrie.git cowrie-git \
    && python3 -m venv cowrie-env \
    && cowrie-env/bin/pip install --no-cache-dir -r cowrie-git/requirements.txt

RUN mkdir -p /cowrie/var/log/cowrie /cowrie/var/lib/cowrie/downloads

COPY --chown=cowrie:cowrie cowrie.cfg /cowrie/cowrie-git/etc/cowrie.cfg

RUN chown -R cowrie:cowrie /cowrie

USER cowrie
WORKDIR /cowrie/cowrie-git

ENV PATH=/cowrie/cowrie-env/bin:${PATH}
ENV PYTHONUNBUFFERED=1

EXPOSE 2222 2223

CMD ["bin/cowrie", "start", "-n"]
