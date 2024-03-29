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
FROM ubuntu:jammy-20240212

USER root

ENV RSTUDIO_VERSION=2023.12.1-402 \
    QUARTO_VERSION=1.4.550 \
    PANDOC_TEMPLATES_VERSION=3.1.6.2 \
    GOLANG_VERSION=1.22.0 \
    HUGO_VERSION=0.122.0 \
    MAMBAFORGE_VERSION=23.11.0-0 \
    DEBIAN_FRONTEND=noninteractive \
    LC_ALL="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8"
ENV RSTUDIO_URL="https://download2.rstudio.org/server/focal/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb" \
  GOLANG_URL="https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz" \
  MAMBAFORGE_URL="https://github.com/conda-forge/miniforge/releases/download/${MAMBAFORGE_VERSION}/Mambaforge-${MAMBAFORGE_VERSION}-Linux-x86_64.sh" \
  QUARTO_PKG="quarto-${QUARTO_VERSION}-linux-amd64.deb" \
  ORACLE_HOME=/opt/oracle/instantclient_21_6
ENV QUARTO_URL="https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/${QUARTO_PKG}"

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
    && update-locale LANG=${LANG} \
    && wget -q ${QUARTO_URL} \
    && dpkg -i ${QUARTO_PKG} \
    && rm ${QUARTO_PKG}

## Install pandoc-templates.
# RUN mkdir -p /opt/pandoc/templates \
#   && cd /opt/pandoc/templates \
#   && wget -q https://github.com/jgm/pandoc-templates/archive/${PANDOC_TEMPLATES_VERSION}.tar.gz \
#   && tar xzf ${PANDOC_TEMPLATES_VERSION}.tar.gz \
#   && rm ${PANDOC_TEMPLATES_VERSION}.tar.gz \
#   && mkdir -p /root/.pandoc \
#   && ln -s /opt/pandoc/templates /root/.pandoc/templates \
#   && mkdir -p ${HOME}/.pandoc \
#   && ln -s /opt/pandoc/templates ${HOME}/.pandoc/templates \
#   && chown -R ${CT_USER}:${CT_GID} ${HOME}/.pandoc

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
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor -o /usr/share/keyrings/packages.microsoft.gpg \
    && echo "deb [arch=amd64,armhf,arm64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/ubuntu/22.04/prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/mssql-release.list \
    && curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \ 
    | gpg --dearmor -o /usr/share/keyrings/apt.postgresql.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/apt.postgresql.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list

RUN apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
        msodbcsql17 \
        mssql-tools \
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
    ACCEPT_EULA=Y \
    OPENSSL_CONF=/etc/ssl/openssl.cnf

# Add a script that we will use to correct permissions after running certain commands
ADD fix-permissions /usr/local/bin/fix-permissions

## Set a default user. Available via runtime flag `--user docker`
## User should also have & own a home directory (e.g. for linked volumes to 
## work properly). Appending the option statement to the openssl config file
## ensures that opensslv3 is able to connect to hosts using older versions.
RUN groupadd --gid ${CT_GID} ${CT_USER} \
  && useradd --create-home --uid ${CT_UID} --gid ${CT_GID} --shell ${SHELL} \
    --password ${CT_USER} ${CT_USER} \
    && echo "Options = UnsafeLegacyRenegotiation" | tee -a ${OPENSSL_CONF}

ENV HOME=/home/${CT_USER}

WORKDIR ${HOME}

RUN echo "deb https://cloud.r-project.org/bin/linux/ubuntu jammy-cran40/" > \
    /etc/apt/sources.list.d/cran40.list \
    && apt-key adv --keyserver keyserver.ubuntu.com \
        --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        r-base \
        r-base-dev \
    && apt-get clean \
    && mkdir -p /usr/local/lib/R/etc/ \
    && mkdir -p --mode ${CT_FMODE} ${HOME}/R/utils \
    && mkdir -p --mode ${CT_FMODE} ${HOME}/R/site-library \
    && echo "R_LIBS_SITE=${R_LIBS_SITE-'${HOME}/R/site-library:/usr/local/lib/R/site-library:/usr/lib/R/site-library:/usr/lib/R/library'}" \
        >> ${HOME}/.Renviron \
    && chown -R ${CT_UID}:${CT_GID} ${HOME}/.Renviron \
    && echo \
        "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl')" \
        >> /usr/local/lib/R/etc/Rprofile.site 

COPY rpkgs.csv ${HOME}/R/utils/rpkgs.csv
COPY Rpkg_install.R ${HOME}/R/utils/Rpkg_install.R
RUN umask 0002 \
    && mkdir -p --mode ${CT_FMODE} ${HOME}/.checkpoint \
    && ln -s /usr/local/${HUGO_VERSION}/hugo /usr/local/bin/hugo \
    && chown -R ${CT_UID}:${CT_GID} ${HOME}/.checkpoint \
    # Install GoLang so Hugo will work
    && wget --quiet ${GOLANG_URL} \
    && tar -C /usr/local -xzf go${GOLANG_VERSION}.linux-amd64.tar.gz \
    && rm go${GOLANG_VERSION}.linux-amd64.tar.gz

ENV PATH=${PATH}:/usr/local/go/bin

WORKDIR ${HOME}

RUN umask 0002 && \
    wget --quiet ${MAMBAFORGE_URL} -O /root/mambaforge.sh && \
    wget --quiet ${MAMBAFORGE_URL}.sha256 -O /root/mambaforge.sh.sha256 && \
    if [ "`sha256sum /root/mambaforge.sh | cut -d\  -f1`" = "`cat /root/mambaforge.sh.sha256 | cut -d\  -f1`" ]; then \
        /bin/bash /root/mambaforge.sh -b -p /opt/conda; fi && \
    rm /root/mambaforge.sh && \
    rm /root/mambaforge.sh.sha256 && \
    /opt/conda/bin/mamba clean -fay && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    find /opt/conda/ -follow -type f -name '*.a' -delete && \
    find /opt/conda/ -follow -type f -name '*.pyc' -delete && \
    find /opt/conda/ -follow -type d -name '__pycache__' -delete && \
    fix-permissions ${CONDA_DIR} \
    && fix-permissions /home/${CT_USER}

USER ${CT_USER}

SHELL ["/bin/bash", "--login", "-c"]

RUN mkdir -p --mode ${CT_FMODE} ${HOME}/.conda/envs
# ARG CONDA_ENV_FILE=${CONDA_ENV_FILE}
# COPY ${CONDA_ENV_FILE} ${HOME}/.conda/${CONDA_ENV_FILE}
COPY conda-env-no-version.yml ${HOME}/.conda/conda-env.yml
COPY conda-env-minimal.yml ${HOME}/.conda/conda-env-minimal.yml

RUN mkdir -p --mode ${CT_FMODE} ${HOME}/.jupyter/lab
ENV JUPYTERLAB_DIR=${HOME}/.jupyter/lab \
    CONDA_DIR=${HOME}/.conda

USER root

# Install RStudio-Server and the IRKernel package
RUN wget -q $RSTUDIO_URL \
    # RStudio-Server depends on this non-standard package
    && wget -q http://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.21_amd64.deb \
    && dpkg -i libssl1.1_*_amd64.deb \
    && dpkg -i rstudio-server-*-amd64.deb \
    && rm *amd64.deb \
    && chown -R ${CT_UID}:${CT_GID} ${HOME}/.conda

USER root

COPY pip.conf .config/pip/pip.conf
ENV PATH=${HOME}/.local/bin:${HOME}/.TinyTeX/bin/x86_64-linux:${PATH} \
    RSESSION_PROXY_RSTUDIO_1_4=true \
    R_LIBS_USER=${HOME}/R/x86_64-pc-linux-gnu-library/4.3

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && chown -R ${CT_UID}:${CT_GID} ${HOME}/.cargo \
    && chown -R ${CT_UID}:${CT_GID} ${HOME}/.rustup \
    && chown -R ${CT_UID}:${CT_GID} ${HOME}/R

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
COPY fonts.zip /usr/local/share/fonts
RUN chown -R ${CT_UID}:${CT_GID} ${HOME}/.config \
    # link the shared object libs provided by conda
    && echo "/opt/conda/lib" >> /etc/ld.so.conf.d/conda.conf \
    # remove conda SO files that would otherwise conflict with system SOs
    && rm /opt/conda/lib/libtinfo* \
    # remove curl SOs installed by conda
    && rm /opt/conda/lib/libcurl* \
    && ldconfig \
    && unzip /usr/local/share/fonts/fonts.zip -d /usr/local/share/fonts \
    && rm /usr/local/share/fonts/fonts.zip \
    && fc-cache -f

USER ${CT_USER}
WORKDIR ${HOME}/work

# Install Quarto extensions, filters because Rust refuses to install them with
# self-signed TLS certificates in the chain.
RUN quarto add --no-prompt quarto-ext/include-code-files \
    && quarto install extension --no-prompt --quiet grantmcdermott/quarto-revealjs-clean \
    && quarto install extension --no-prompt --quiet andrewheiss/hikmah-pdf \
    && quarto install extension --no-prompt --quiet andrewheiss/hikmah-manuscript-docx \
    && quarto install extension --no-prompt --quiet shafayetShafee/metropolis
CMD [ "/bin/bash" ]
