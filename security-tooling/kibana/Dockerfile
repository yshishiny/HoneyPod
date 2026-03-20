FROM docker.elastic.co/kibana/kibana:8.9.1

# Connect to Elasticsearch via Railway internal DNS
ENV ELASTICSEARCH_HOSTS=http://siem.railway.internal:9200

# Disable the interactive setup wizard (Kibana 8.x feature)
ENV xpack.security.enabled=false

# Explicitly set the server host to listen on all interfaces
ENV SERVER_HOST=0.0.0.0

EXPOSE 5601

CMD ["/bin/bash", "-c", "rm -rf /usr/share/kibana/node_modules/@kbn/interactive-setup-plugin 2>/dev/null; kibana --allow-root"]
