FROM redis:7-alpine

EXPOSE 6379

CMD ["redis-server", "--requirepass", "${REDIS_PASSWORD:-honeypod-redis-password-2024}"]
