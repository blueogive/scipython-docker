# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
FROM ubuntu:bionic-20190307

USER root

RUN apt-get update --fix-missing && \
    apt-get install -y --no-install-recommends \
        wget \
        bzip2 \
        ca-certificates \
        libssl1.0-dev \
        curl \
        gnupg2 \
        gosu \
        git \
        locales \
        make && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

## Install Microsoft ODBC driver and SQL commandline tools
RUN curl -o microsoft.asc https://packages.microsoft.com/keys/microsoft.asc \
    && apt-key add microsoft.asc \
    && rm microsoft.asc \
    && curl https://packages.microsoft.com/config/ubuntu/18.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
        msodbcsql17 \
        mssql-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

## Set environment variables
ENV LC_ALL="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    PATH=/opt/conda/bin:/opt/mssql-tools/bin:${PATH} \
    SHELL=/bin/bash \
    CT_USER=docker \
    CT_UID=1000 \
    CT_GID=100 \
    TINI_VERSION=v0.16.1

## Setup the locale
RUN /usr/sbin/locale-gen ${LC_ALL} \
    && /usr/sbin/update-locale LANG=${LANG}

RUN wget --quiet \
    https://repo.anaconda.com/miniconda/Miniconda3-4.5.12-Linux-x86_64.sh \
    -O /root/miniconda.sh && \
    if [ "`md5sum /root/miniconda.sh | cut -d\  -f1`" = "866ae9dff53ad0874e1d1a60b1ad1ef8" ]; then \
        /bin/bash /root/miniconda.sh -b -p /opt/conda; fi && \
    rm /root/miniconda.sh && \
    /opt/conda/bin/conda clean -tipsy && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh

ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini

## Set a default user. Available via runtime flag `--user docker`
## User should also have & own a home directory (e.g. for linked volumes to work properly).
RUN useradd --create-home --uid ${CT_UID} --gid ${CT_GID} --shell ${SHELL} ${CT_USER} \
    && chmod +x /usr/bin/tini

WORKDIR /root
COPY conda-env.yml conda-env.yml
RUN /opt/conda/bin/conda config --add channels conda-forge \
    && /opt/conda/bin/conda env update -n base --file conda-env.yml \
    && /opt/conda/bin/conda clean -tipsy \
    && rm conda-env.yml

ENV HOME=/home/${CT_USER}
WORKDIR ${HOME}
USER ${CT_USER}
RUN echo ". /opt/conda/etc/profile.d/conda.sh" >> ${HOME}/.bashrc && \
    echo "conda activate base" >> ${HOME}/.bashrc && \
    mkdir ${HOME}/work
SHELL [ "/bin/bash", "--login", "-c"]
RUN source ${HOME}/.bashrc \
    && conda activate base \
    && git clone https://github.com/blueogive/pyncrypt.git \
    && pip install --user --no-cache-dir --disable-pip-version-check pyncrypt/ \
    && rm -rf pyncrypt \
    && mkdir -p .config/pip
COPY pip.conf .config/pip/pip.conf
WORKDIR ${HOME}/work

ARG VCS_URL=${VCS_URL}
ARG VCS_REF=${VCS_REF}
ARG BUILD_DATE=${BUILD_DATE}

# Add image metadata
LABEL org.label-schema.license="https://opensource.org/licenses/MIT" \
    org.label-schema.vendor="Anaconda, Inc. and Python Foundation, Dockerfile provided by Mark Coggeshall" \
    org.label-schema.name="Scientific Python Foundation" \
    org.label-schema.description="Docker image including a foundational scientific Python stack based on Miniconda and Python 3." \
    org.label-schema.vcs-url=${VCS_URL} \
    org.label-schema.vcs-ref=${VCS_REF} \
    org.label-schema.build-date=${BUILD_DATE} \
    maintainer="Mark Coggeshall <mark.coggeshall@gmail.com>"

USER root

ENTRYPOINT [ "/usr/bin/tini", "--" ]
CMD [ "/bin/bash" ]
