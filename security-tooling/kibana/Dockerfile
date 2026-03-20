FROM docker.elastic.co/kibana/kibana:8.9.1

ENV ELASTICSEARCH_HOSTS=http://siem.railway.internal:9200
ENV xpack.security.enabled=false

EXPOSE 5601

CMD ["kibana"]
