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
FROM ubuntu:bionic-20190718

USER root

ENV RSTUDIO_VERSION=1.2.1335 \
    PANDOC_TEMPLATES_VERSION=2.7.2
ENV RSTUDIO_URL="https://download2.rstudio.org/server/bionic/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb"

RUN apt-get update --fix-missing \
    && apt-get install -y --no-install-recommends \
        bzip2 \
        ca-certificates \
        curl \
        gdebi-core \
        git \
        gnupg2 \
        gosu \
        libapparmor1 \
        libclang-dev \
        libssl1.0-dev \
        locales \
        lsb-release \
        make \
        psmisc \
        sudo \
        wget \
        build-essential \
        fonts-texgyre \
        gfortran \
        default-jdk \
        dpkg \
        pandoc \
        pandoc-citeproc \
        # Linux system packages that are dependencies of R packages
        libxml2-dev \
        libcurl4-gnutls-dev \
        liblapack-dev \
        libgdal-dev \
        libgeos-dev \
        libproj-dev \
        libcairo2-dev \
        libssl1.0-dev \
        unzip \
        # Allow R pkgs requiring X11 to install/run using virtual framebuffer
        xvfb \
        xauth \
        xfonts-base \
        # MRO dependencies that don't sort themselves out on their own:
        less \
        libgomp1 \
        libpango-1.0-0 \
        libxt6 \
        libsm6 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

## Install pandoc-templates.
RUN mkdir -p /opt/pandoc/templates \
  && cd /opt/pandoc/templates \
  && wget -q https://github.com/jgm/pandoc-templates/archive/${PANDOC_TEMPLATES_VERSION}.tar.gz \
  && tar xzf ${PANDOC_TEMPLATES_VERSION}.tar.gz \
  && rm ${PANDOC_TEMPLATES_VERSION}.tar.gz \
  && mkdir -p /root/.pandoc \
  && ln -s /opt/pandoc/templates /root/.pandoc/templates \
  && mkdir -p ${HOME}/.pandoc \
  && ln -s /opt/pandoc/templates ${HOME}/.pandoc/templates \
  && chown -R ${CT_USER}:${CT_GID} ${HOME}/.pandoc

## Install Microsoft and Postgres ODBC drivers and SQL commandline tools
RUN curl -o microsoft.asc https://packages.microsoft.com/keys/microsoft.asc \
    && apt-key add microsoft.asc \
    && rm microsoft.asc \
    && curl https://packages.microsoft.com/config/ubuntu/18.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
        msodbcsql17 \
        mssql-tools \
        odbc-postgresql \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm /etc/apt/sources.list.d/mssql-release.list

## Set environment variables
ENV LC_ALL="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    PATH=/opt/conda/bin:/opt/mssql-tools/bin:/usr/lib/rstudio-server/bin:${PATH} \
    MRO_VERSION_MAJOR=3 \
    MRO_VERSION_MINOR=5 \
    MRO_VERSION_BUGFIX=3 \
    SHELL=/bin/bash \
    CT_USER=docker \
    CT_UID=1000 \
    CT_GID=100 \
    CT_FMODE=0775 \
    CONDA_DIR=/opt/conda \
    FONT_LOCAL=/usr/local/share/fonts

COPY fonts.zip ${FONT_LOCAL}

WORKDIR ${FONT_LOCAL}

## Setup the locale
RUN unzip fonts.zip \
    && rm fonts.zip \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8 \
    && git clone --branch release --depth 1 \
    'https://github.com/adobe-fonts/source-code-pro.git' \
    "${FONT_LOCAL}/adobe-fonts/source-code-pro" \
    # XeTeX gets hung up by these WOFF files, if they are present.
    # Looks like a bug.
    && rm -rf ${FONT_LOCAL}/adobe-fonts/source-code-pro/WOFF \
    && fc-cache -f -v "${FONT_LOCAL}"

RUN wget --quiet \
    https://repo.anaconda.com/miniconda/Miniconda3-4.7.10-Linux-x86_64.sh \
    -O /root/miniconda.sh && \
    if [ "`md5sum /root/miniconda.sh | cut -d\  -f1`" = "1c945f2b3335c7b2b15130b1b2dc5cf4" ]; then \
        /bin/bash /root/miniconda.sh -b -p /opt/conda; fi && \
    rm /root/miniconda.sh && \
    /opt/conda/bin/conda clean -tipsy && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh

# Add a script that we will use to correct permissions after running certain commands
ADD fix-permissions /usr/local/bin/fix-permissions

## Set a default user. Available via runtime flag `--user docker`
## User should also have & own a home directory (e.g. for linked volumes to work properly).
RUN useradd --create-home --uid ${CT_UID} --gid ${CT_GID} --shell ${SHELL} ${CT_USER}

ENV HOME=/home/${CT_USER} \
  MRO_VERSION=${MRO_VERSION_MAJOR}.${MRO_VERSION_MINOR}.${MRO_VERSION_BUGFIX}

WORKDIR ${HOME}

## Download and install MRO & MKL
RUN curl -LO -# https://mran.blob.core.windows.net/install/mro/${MRO_VERSION}/ubuntu/microsoft-r-open-${MRO_VERSION}.tar.gz \
    && tar -xzf microsoft-r-open-${MRO_VERSION}.tar.gz
WORKDIR ${HOME}/microsoft-r-open
RUN ./install.sh -a -u

WORKDIR ${HOME}

# Clean up downloaded files and install libpng
RUN rm microsoft-r-open-*.tar.gz && \
    rm -r microsoft-r-open && \
    curl -LO -# https://mirrors.kernel.org/ubuntu/pool/main/libp/libpng/libpng12-0_1.2.54-1ubuntu1_amd64.deb && \
    dpkg -i libpng12-0_1.2.54-1ubuntu1_amd64.deb && \
    rm libpng12-0_1.2.54-1ubuntu1_amd64.deb

COPY Renviron.site Renviron.site
RUN mv Renviron.site /opt/microsoft/ropen/$MRO_VERSION/lib64/R/etc

COPY rpkgs.csv rpkgs.csv
COPY Rpkg_install.R Rpkg_install.R
RUN mkdir -p --mode ${CT_FMODE} ${HOME}/.checkpoint && \
    xvfb-run Rscript Rpkg_install.R && \
    rm rpkgs.csv Rpkg_install.R && \
    chown -R ${CT_UID}:${CT_GID} ${HOME}/.checkpoint && \
    chown -R ${CT_USER}:${CT_GID} ${HOME}/bin && \
    chown -R ${CT_USER}:${CT_GID} ${HOME}/.TinyTeX && \
    rm ${HOME}/.wget-hsts

RUN fix-permissions ${CONDA_DIR} \
    && fix-permissions /home/${CT_USER}

USER ${CT_USER}

ARG CONDA_ENV_FILE=${CONDA_ENV_FILE}
COPY ${CONDA_ENV_FILE} ${CONDA_ENV_FILE}
RUN /opt/conda/bin/conda config --add channels conda-forge \
    && /opt/conda/bin/conda config --set channel_priority strict \
    && /opt/conda/bin/conda env update -n base --file ${CONDA_ENV_FILE} \
    && /opt/conda/bin/conda install conda-build \
    && /opt/conda/bin/conda build purge-all \
    && rm ${CONDA_ENV_FILE}
RUN jupyter labextension install @jupyterlab/hub-extension \
    && npm cache clean --force \
    && jupyter notebook --generate-config \
    && rm -rf ${CONDA_DIR}/share/jupyter/lab/staging \
    && rm -rf /home/${CT_USER}/.cache/yarn \
    && fix-permissions ${CONDA_DIR} \
    && fix-permissions /home/${CT_USER}

USER root

RUN jupyter lab build

# Install RStudio-Server and the IRKernel package
RUN wget -q $RSTUDIO_URL \
    && dpkg -i rstudio-server-*-amd64.deb \
    && rm rstudio-server-*-amd64.deb \
    && Rscript -e "install.packages('IRkernel')" \
    && Rscript -e "IRkernel::installspec(user=FALSE)" \
    && fix-permissions ${HOME}/.local

COPY Rprofile.site /opt/conda/lib/R/etc

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
    && mkdir -p .config/pip \
    && fix-permissions ${HOME}/work
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

EXPOSE 8888
WORKDIR ${HOME}/work

# Add local files as late as possible to avoid cache busting
COPY start.sh /usr/local/bin/
COPY start-notebook.sh /usr/local/bin/
COPY start-singleuser.sh /usr/local/bin/
COPY jupyter_notebook_config.py /etc/jupyter/
RUN fix-permissions /etc/jupyter/

CMD [ "/bin/bash" ]
