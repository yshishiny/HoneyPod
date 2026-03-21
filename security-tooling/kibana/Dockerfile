FROM docker.elastic.co/kibana/kibana:8.9.1

# Connect to Elasticsearch via Railway internal DNS
ENV ELASTICSEARCH_HOSTS=http://siem.railway.internal:9200

# Disable security features
ENV xpack.security.enabled=false
ENV xpack.security.enrollment.enabled=false

# Explicitly set the server host to listen on all interfaces
ENV SERVER_HOST=0.0.0.0

EXPOSE 5601

# Run the default kibana entrypoint
CMD ["kibana"]
