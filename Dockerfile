FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y ansible ssh && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /ansible

COPY . .

# Create a local inventory file for localhost testing if needed,
# though we are just doing syntax check mainly.
RUN echo "[localhost]\nlocalhost ansible_connection=local" > inventory/docker_hosts.ini

ENTRYPOINT ["ansible-playbook"]
CMD ["playbook.yml", "--syntax-check"]
