FROM python:3.11-slim-bookworm

RUN apt-get update && apt-get install -y \
    git curl wget golang-go \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/caldera

RUN git clone --depth 1 --branch v5.0.0 --recursive \
    https://github.com/mitre/caldera.git . \
    && pip install --no-cache-dir -r requirements.txt

COPY caldera-local.yml conf/local.yml

ENV PYTHONUNBUFFERED=1

EXPOSE 8888

CMD ["sh", "-c", "python3 server.py --insecure --port ${PORT:-8888}"]
