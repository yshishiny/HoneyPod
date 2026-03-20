FROM docker.elastic.co/logstash/logstash:8.9.1

ENV LS_JAVA_OPTS="-Xms256m -Xmx256m"

# Remove the default pipeline config
RUN rm -f /usr/share/logstash/pipeline/logstash.conf

# Copy our pipeline config
COPY logstash.conf /usr/share/logstash/pipeline/logstash.conf

EXPOSE 514 5000

CMD ["logstash"]
