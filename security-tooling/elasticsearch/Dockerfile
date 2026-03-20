FROM docker.elastic.co/elasticsearch/elasticsearch:8.9.1

ENV discovery.type=single-node
ENV ES_JAVA_OPTS="-Xms512m -Xmx512m"
ENV xpack.security.enabled=true
ENV ELASTIC_PASSWORD=${ELASTIC_PASSWORD:-honeypod-elastic-password-2024}
ENV xpack.security.enrollment.enabled=false

EXPOSE 9200

CMD ["elasticsearch"]
