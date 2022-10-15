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
FROM ubuntu:focal-20220922

USER root

ENV RSTUDIO_VERSION=2022.07.2-576 \
    PANDOC_TEMPLATES_VERSION=2.19.2 \
    GOLANG_VERSION=1.19.2 \
    HUGO_VERSION=0.104.3 \
    MAMBAFORGE_VERSION=4.14.0-0 \
    DEBIAN_FRONTEND=noninteractive \
    LC_ALL="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8"
ENV RSTUDIO_URL="https://download2.rstudio.org/server/bionic/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb" \
  GOLANG_URL="https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz" \
  MAMBAFORGE_URL="https://github.com/conda-forge/miniforge/releases/download/${MAMBAFORGE_VERSION}/Mambaforge-${MAMBAFORGE_VERSION}-Linux-x86_64.sh" \
  ORACLE_HOME=/opt/oracle/instantclient_21_6

RUN apt-get update --fix-missing \
    && apt-get install -y --no-install-recommends \
        bzip2 \
        cmake \
        ca-certificates \
        curl \
        gdebi-core \
        git \
        gnupg2 \
        gosu \
        libapparmor1 \
        libclang-dev \
        libssl-dev \
        locales \
        lsb-release \
        make \
        openssh-client \
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
        libcurl4-openssl-dev \
        liblapack-dev \
        # libgdal-dev \
        # default-libmysqlclient-dev \
        # libmysqlclient-dev \
        libgeos-dev \
        libproj-dev \
        libcairo2-dev \
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
        # Packages required by several useful R packages
        libopenblas-dev \
        libv8-dev \
        libharfbuzz-dev \
        libfribidi-dev \
        libfreetype6-dev \
        libpng-dev \
        libtiff5-dev \
        libjpeg-dev \
        # unixodbc-dev must be installed before the Microsoft ODBC driver to
        # avoid version conflicts.
        unixodbc-dev \
        # required by Oracl Instant Client
        libaio1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen ${LANG} \
    && dpkg-reconfigure locales \
    && update-locale LANG=${LANG}

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

## Install Oracle Instant Client, tools
RUN mkdir /opt/oracle
WORKDIR /opt/oracle
RUN curl -o instantclient-basiclite-linux.x64-21.6.0.0.0dbru.zip \
    https://download.oracle.com/otn_software/linux/instantclient/216000/instantclient-basiclite-linux.x64-21.6.0.0.0dbru.zip \
    && curl -o instantclient-sqlplus-linux.x64-21.6.0.0.0dbru.zip https://download.oracle.com/otn_software/linux/instantclient/216000/instantclient-sqlplus-linux.x64-21.6.0.0.0dbru.zip \
    && unzip -oq 'instantclient-*.zip' \
    && rm instantclient-*.zip

WORKDIR ${ORACLE_HOME}
RUN mkdir bin \
    && mv sqlplus bin \
    && mkdir -p sqlplus/admin \
    && mv glogin.sql sqlplus/admin \
    && echo ${ORACLE_HOME} > \
        /etc/ld.so.conf.d/oracle-instantclient.conf \
    && ldconfig

## Install Microsoft and Postgres ODBC drivers and SQL commandline tools
RUN curl -o microsoft.asc https://packages.microsoft.com/keys/microsoft.asc \
    && apt-key add microsoft.asc \
    && rm microsoft.asc \
    && curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && curl https://packages.microsoft.com/config/ubuntu/18.04/mssql-server-2019.list > /etc/apt/sources.list.d/mssql-is-release.list \
    && echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

RUN apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
        msodbcsql17 \
        mssql-tools \
        mssql-server-is \
        odbc-postgresql \
        postgresql-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

## Set environment variables
ENV PATH=/opt/conda/bin:/opt/mssql-tools/bin:/usr/lib/rstudio-server/bin:/opt/ssis/bin:${ORACLE_HOME}/bin:${PATH} \
    NLS_LANG=AMERICAN_AMERICA.UTF8 \
    SHELL=/bin/bash \
    CT_USER=docker \
    CT_UID=1000 \
    CT_GID=1000 \
    CT_FMODE=0775 \
    SSIS_PID=Developer \
    ACCEPT_EULA=Y \
    CONDA_DIR=/opt/conda

# Add a script that we will use to correct permissions after running certain commands
ADD fix-permissions /usr/local/bin/fix-permissions

## Set a default user. Available via runtime flag `--user docker`
## User should also have & own a home directory (e.g. for linked volumes to work properly).
RUN groupadd --gid ${CT_GID} ${CT_USER} \
  && useradd --create-home --uid ${CT_UID} --gid ${CT_GID} --shell ${SHELL} \
    --password ${CT_USER} ${CT_USER}

ENV HOME=/home/${CT_USER}

WORKDIR ${HOME}

RUN echo "deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/" > \
    /etc/apt/sources.list.d/cran40.list \
    && apt-key adv --keyserver keyserver.ubuntu.com \
        --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        r-base \
        r-base-dev \
        r-cran-littler \
    && apt-get clean \
    && mkdir -p /usr/local/lib/R/etc/ \
    && echo "R_LIBS_SITE=${R_LIBS_SITE-'/usr/local/lib/R/site-library:/usr/lib/R/site-library:/usr/lib/R/library'}" \
        >> ${HOME}/.Renviron \
    && chown -R ${CT_UID}:${CT_GID} ${HOME}/.Renviron \
    && echo \
        "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl')" \
        >> /usr/local/lib/R/etc/Rprofile.site

COPY rpkgs.csv rpkgs.csv
COPY Rpkg_install.R Rpkg_install.R
RUN umask 0002 && \
    mkdir -p --mode ${CT_FMODE} ${HOME}/.checkpoint && \
    Rscript Rpkg_install.R && \
    rm rpkgs.csv Rpkg_install.R && \
    ln -s /usr/local/${HUGO_VERSION}/hugo /usr/local/bin/hugo && \
    chown -R ${CT_UID}:${CT_GID} ${HOME}/.checkpoint && \
    chown -R ${CT_USER}:${CT_GID} ${HOME}/bin && \
    chown -R ${CT_USER}:${CT_GID} ${HOME}/.TinyTeX && \
    # Install GoLang so Hugo will work
    wget --quiet ${GOLANG_URL} && \
    tar -C /usr/local -xzf go${GOLANG_VERSION}.linux-amd64.tar.gz && \
    rm go${GOLANG_VERSION}.linux-amd64.tar.gz

ENV PATH=${PATH}:/usr/local/go/bin

WORKDIR ${HOME}

RUN umask 0002 && \
    wget --quiet ${MAMBAFORGE_URL} -O /root/mambaforge.sh && \
    wget --quiet ${MAMBAFORGE_URL}.sha256 -O /root/mambaforge.sh.sha256 && \
    if [ "`sha256sum /root/mambaforge.sh | cut -d\  -f1`" = "`cat /root/mambaforge.sh.sha256 | cut -d\  -f1`" ]; then \
        /bin/bash /root/mambaforge.sh -b -p /opt/conda; fi && \
    rm /root/mambaforge.sh && \
    rm /root/mambaforge.sh.sha256 && \
    /opt/conda/bin/mamba clean -atipy && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    fix-permissions ${CONDA_DIR} \
    && fix-permissions /home/${CT_USER}

USER ${CT_USER}

SHELL [ "/bin/bash", "--login", "-c"]

ARG CONDA_ENV_FILE=${CONDA_ENV_FILE}
COPY ${CONDA_ENV_FILE} ${CONDA_ENV_FILE}

RUN umask 0002 \
    # Left overs from my experimentation with micromamba. It looks promising,
    # but it requires special syntax to execute commands within its environments within a Dockerfile. See https://github.com/mamba-org/micromamba-docker for hints.
# RUN wget -qO- https://micromamba.snakepit.net/api/micromamba/linux-64/latest | tar -xvj bin/micromamba 
# RUN ${HOME}/bin/micromamba shell init -s bash -p ${HOME}/micromamba 
# RUN source ${HOME}/.bashrc 
# RUN ${HOME}/bin/micromamba create -n base -r conda/env --file ${CONDA_ENV_FILE}
# RUN ${HOME}/bin/micromamba clean --all --yes
    && /opt/conda/bin/mamba env update -n base --file ${CONDA_ENV_FILE} \
    && /opt/conda/bin/mamba config --set channel_priority strict \
    && /opt/conda/bin/mamba clean -atipy \
    && /opt/conda/bin/mamba init
RUN rm ${CONDA_ENV_FILE}

RUN mkdir -p ${HOME}/.jupyter/lab
ENV JUPYTERLAB_DIR=${HOME}/.jupyter/lab
# RUN mamba init \
#     && ["source", "${HOME}/.bashrc"] \
#     && mamba activate base \
RUN umask 0002 \
#     && ["/opt/conda/bin/mamba", "activate",  "base"] \
    # && ["jupyter", "labextension", "install", "@jupyterlab/hub-extension"] 
    && jupyter labextension install @jupyterlab/hub-extension \
    && npm cache clean --force \
    && jupyter notebook --generate-config \
    && jupyter lab build \
    && rm -rf ${CONDA_DIR}/share/jupyter/lab/staging \
    && rm -rf ${HOME}/.cache/yarn

USER root

# Install RStudio-Server and the IRKernel package
RUN wget -q $RSTUDIO_URL \
    && dpkg -i rstudio-server-*-amd64.deb \
    && rm rstudio-server-*-amd64.deb \
    && Rscript -e "install.packages('IRkernel')" \
    && Rscript -e "IRkernel::installspec(user=FALSE)" \
    && chown -R ${CT_UID}:${CT_GID} ${HOME}/.local \
    && chown -R ${CT_UID}:${CT_GID} ${HOME}/.cache \
    && chown -R ${CT_UID}:${CT_GID} ${HOME}/.conda \
    && chown -R ${CT_UID}:${CT_GID} ${HOME}/.ipython

USER ${CT_USER}

RUN mkdir ${HOME}/work

USER root

RUN umask 0002 \
    && source ${HOME}/.bashrc \
    && git clone https://github.com/blueogive/pyncrypt.git \
    && pip install --no-cache-dir --disable-pip-version-check pyncrypt/ \
    && rm -rf pyncrypt \
    && git clone https://github.com/jupyterhub/jupyter-rsession-proxy.git \
    && pip install --no-cache-dir --disable-pip-version-check jupyter-rsession-proxy/ \
    && rm -rf jupyter-rsession-proxy \
    && mkdir -p .config/pip \
    && fix-permissions ${HOME}/work \
    && touch ${HOME}/.gitconfig \
    && mkdir ${HOME}/.ssh \
    && rm ${HOME}/.wget-hsts \
    && chmod 0700 ${HOME}/.ssh \
    && chown -R ${CT_UID}:${CT_GID} ${HOME}/.ssh \
    && chown -R ${CT_UID}:${CT_GID} ${HOME}/.gitconfig \
    && mkdir -p ${HOME}/R/x86_64-pc-linux-gnu-library/4.2 \
    && chown -R ${CT_UID}:${CT_GID} ${HOME}/R
COPY pip.conf .config/pip/pip.conf
ENV PATH=${HOME}/.local/bin:${HOME}/.TinyTeX/bin/x86_64-linux:${PATH} \
    RSESSION_PROXY_RSTUDIO_1_4=true \
    R_LIBS_USER=${HOME}/R/x86_64-pc-linux-gnu-library/4.2

# Install Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y

ARG VCS_URL=${VCS_URL}
ARG VCS_REF=${VCS_REF}
ARG BUILD_DATE=${BUILD_DATE}

# Add image metadata
LABEL org.label-schema.license="https://opensource.org/licenses/MIT" \
    org.label-schema.vendor="Conda-forge Community and Python Foundation, Dockerfile provided by Mark Coggeshall" \
    org.label-schema.name="Scientific Python Foundation" \
    org.label-schema.description="Docker image including a foundational scientific Python stack based on Mambaforge and Python 3." \
    org.label-schema.vcs-url=${VCS_URL} \
    org.label-schema.vcs-ref=${VCS_REF} \
    org.label-schema.build-date=${BUILD_DATE} \
    maintainer="Mark Coggeshall <mark.coggeshall@gmail.com>"

# jupyter port
EXPOSE 8888

# Add local files as late as possible to avoid cache busting
COPY start.sh /usr/local/bin/
COPY start-notebook.sh /usr/local/bin/
COPY start-singleuser.sh /usr/local/bin/
COPY jupyter_notebook_config.py /etc/jupyter/
COPY ssisconfhelper.py /opt/ssis/lib/ssis-conf/
RUN fix-permissions /etc/jupyter/ \
    && chown -R ${CT_UID}:${CT_GID} ${HOME}/.config \
    # link the shared object libs provided by conda
    && echo "/opt/conda/lib" >> /etc/ld.so.conf.d/conda.conf \
    # remove conda SO files that would otherwise conflict with system SOs
    && rm /opt/conda/lib/libtinfo* \
    # remove curl SOs installed by conda
    && rm /opt/conda/lib/libcurl* \
    && ldconfig

RUN /opt/ssis/bin/ssis-conf -n setup

USER ${CT_USER}
WORKDIR ${HOME}/work
CMD [ "/bin/bash" ]
