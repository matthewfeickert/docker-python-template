ARG BASE_IMAGE=python:3.10-slim-bullseye
FROM ${BASE_IMAGE} as base

FROM base as builder

SHELL [ "/bin/bash", "-c" ]

# Set PATH to pickup virtualenv by default
ENV PATH=/usr/local/venv/bin:"${PATH}"
RUN python -m venv /usr/local/venv && \
    . /usr/local/venv/bin/activate && \
    python -m pip --no-cache-dir install --upgrade pip setuptools wheel && \
    python -m pip --no-cache-dir install \
        awkward \
        hist \
        mplhep \
        iminuit

# Build lots of complicated software with lots of dependencies
# but install them under /usr/local/venv
# ...

FROM base

SHELL [ "/bin/bash", "-c" ]
ENV PATH=/usr/local/venv/bin:"${PATH}"

# Install any packages needed by default user
RUN apt-get -qq -y update && \
    apt-get -qq -y install \
      wget \
      curl \
      git && \
    apt-get -y autoclean && \
    apt-get -y autoremove && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user "docker" with uid 1000
RUN adduser \
      --shell /bin/bash \
      --gecos "default user" \
      --uid 1000 \
      --disabled-password \
      docker && \
    chown -R docker /home/docker && \
    mkdir -p /home/docker/work && \
    chown -R docker /home/docker/work && \
    mkdir /work && \
    chown -R docker /work && \
    printf '\nexport PATH=/usr/local/venv/bin:"${PATH}"\n' >> /root/.bashrc && \
    cp /root/.bashrc /etc/.bashrc && \
    echo 'if [ -f /etc/.bashrc ]; then . /etc/.bashrc; fi' >> /etc/profile

COPY --from=builder --chown=docker /usr/local/venv /usr/local/venv

USER docker

ENV USER ${USER}
ENV HOME /home/docker
WORKDIR ${HOME}/work
