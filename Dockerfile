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
        iminuit && \
    python -m pip list

# Build lots of complicated software with lots of dependencies
# but install them under /usr/local/venv
# ...

RUN apt-get -qq -y update && \
    apt-get -qq -y install \
      gcc \
      g++ \
      zlib1g \
      zlib1g-dev \
      libbz2-dev \
      wget \
      curl \
      make \
      cmake \
      rsync \
      libboost-all-dev && \
    apt-get -y autoclean && \
    apt-get -y autoremove && \
    rm -rf /var/lib/apt/lists/*

ARG FASTJET_VERSION=3.4.0
RUN mkdir /code && \
    cd /code && \
    wget http://fastjet.fr/repo/fastjet-${FASTJET_VERSION}.tar.gz && \
    tar xvfz fastjet-${FASTJET_VERSION}.tar.gz && \
    cd fastjet-${FASTJET_VERSION} && \
    ./configure --help && \
    export CXX=$(command -v g++) && \
    ./configure \
      --prefix=/usr/local/venv && \
    make --jobs $(nproc --ignore=1) && \
    make check && \
    make install && \
    python -m pip --no-cache-dir install --upgrade "fastjet~=${FASTJET_VERSION}.0" && \
    rm -rf /code

FROM base

SHELL [ "/bin/bash", "-c" ]
ENV PATH=/usr/local/venv/bin:"${PATH}"

# Install any packages needed by default user
RUN apt-get -qq -y update && \
    apt-get -qq -y install \
      gcc \
      g++ \
      wget \
      curl \
      git \
      vim \
      emacs && \
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

COPY --from=builder --chown=docker --chmod=777 /usr/local/venv /usr/local/venv

USER docker

ENV USER ${USER}
ENV HOME /home/docker
WORKDIR ${HOME}/work
