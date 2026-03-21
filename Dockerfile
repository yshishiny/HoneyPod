FROM nginx:1.25-alpine

COPY docs/status.html /usr/share/nginx/html/index.html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
