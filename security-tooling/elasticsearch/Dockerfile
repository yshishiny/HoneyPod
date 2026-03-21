FROM docker.elastic.co/elasticsearch/elasticsearch:7.17.23

ENV discovery.type=single-node
ENV ES_JAVA_OPTS="-Xms512m -Xmx512m"

EXPOSE 9200

CMD ["elasticsearch"]
