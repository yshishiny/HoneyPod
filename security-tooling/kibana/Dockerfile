FROM docker.elastic.co/kibana/kibana:7.17.23

# Connect to Elasticsearch via Railway internal DNS
ENV ELASTICSEARCH_HOSTS=http://siem.railway.internal:9200

# Explicitly set the server host to listen on all interfaces
ENV SERVER_HOST=0.0.0.0

EXPOSE 5601

CMD ["kibana"]
