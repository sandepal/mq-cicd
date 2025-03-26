FROM quay.io/openshift/origin-cli:latest

USER root

# Install git
RUN yum install -y git && yum clean all

# Revert to non-root user for safety
USER 1001