# logstash configuration - TODO: Much better documentation needed
These files and folder structure should reside in /etc/logstash
The aggregate function is not thread-safe, so single workers are required.

Each pipeline should be defined in pipelines.yml with a single worker and their
separate folders for maintaining state
