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
FROM ubuntu:noble

USER root

ENV RSTUDIO_VERSION=2026.09.0-174 \
    QUARTO_VERSION=1.10.18 \
    # MAMBAFORGE_VERSION=24.11.0-0 \
    NVM_VERSION=0.40.4 \
    RIPGREP_VERSION=15.2.0 \
    FZF_VERSION=0.74.4 \
    GOPASS_VERSION=1.17.3 \
    DEBIAN_FRONTEND=noninteractive \
    LC_ALL="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8"
ENV RSTUDIO_URL="https://download2.rstudio.org/server/jammy/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb" \
  QUARTO_PKG="quarto-${QUARTO_VERSION}-linux-amd64.deb"
#   ORACLE_CLIENT_VERSION="23.8.0.25.04" \
#   ORACLE_CLIENT_FOLDER="2380000" \
#   ORACLE_HOME=/opt/oracle/instantclient_23_8
ENV QUARTO_URL="https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/${QUARTO_PKG}"

RUN apt-get update --fix-missing \
    && apt-get install -y --no-install-recommends \
        bzip2 \
        cmake \
        ca-certificates \
        curl \
        gdebi-core \
        gnupg2 \
        libapparmor1 \
        libclang-dev \
        libssl-dev \
        locales \
        lsb-release \
        make \
        openssh-client \
        psmisc \
        software-properties-common \
        sudo \
        wget \
        build-essential \
        gfortran \
        default-jdk \
        dpkg \
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
        libxkbcommon-x11-0 \
        libgbm1 \
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
        # required by Oracle Instant Client
        # libaio1
    && add-apt-repository ppa:git-core/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen ${LANG} \
    && dpkg-reconfigure locales \
    && update-locale LANG=${LANG} \
    && wget -q ${QUARTO_URL} \
    && dpkg -i ${QUARTO_PKG} \
    && rm ${QUARTO_PKG}

## Install Oracle Instant Client, tools
# RUN mkdir /opt/oracle
# WORKDIR /opt/oracle

# RUN curl -o instantclient-basiclite-linux.x64-${ORACLE_CLIENT_VERSION}.zip https://download.oracle.com/otn_software/linux/instantclient/${ORACLE_CLIENT_FOLDER}/instantclient-basiclite-linux.x64-${ORACLE_CLIENT_VERSION}.zip \
#     && curl -o instantclient-sqlplus-linux.x64-${ORACLE_CLIENT_VERSION}.zip https://download.oracle.com/otn_software/linux/instantclient/${ORACLE_CLIENT_FOLDER}/instantclient-sqlplus-linux.x64-${ORACLE_CLIENT_VERSION}.zip \
#     && unzip -oq 'instantclient-*.zip' \
#     && rm instantclient-*.zip

# WORKDIR ${ORACLE_HOME}
# RUN mkdir bin \
#     && mv sqlplus bin \
#     && mkdir -p sqlplus/admin \
#     && mv glogin.sql sqlplus/admin \
#     && echo ${ORACLE_HOME} > \
#         /etc/ld.so.conf.d/oracle-instantclient.conf \
#     && ldconfig

## Install Microsoft and Postgres ODBC drivers and SQL commandline tools
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor -o /usr/share/keyrings/packages.microsoft.gpg \
    && echo "deb [arch=amd64,armhf,arm64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/ubuntu/24.04/prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/mssql-release.list \
    && curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \ 
    | gpg --dearmor -o /usr/share/keyrings/apt.postgresql.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/apt.postgresql.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list

RUN apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
        msodbcsql18 \
        mssql-tools18 \
        odbc-postgresql \
        postgresql-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

## Set environment variables
# ENV PATH=/opt/mssql-tools18/bin:/usr/lib/rstudio-server/bin:${ORACLE_HOME}/bin:${PATH} \
ENV PATH=/opt/mssql-tools18/bin:/usr/lib/rstudio-server/bin:${PATH} \
    NLS_LANG=AMERICAN_AMERICA.UTF8 \
    SHELL=/bin/bash \
    CT_USER=docker \
    CT_UID=1000 \
    CT_GID=1000 \
    CT_FMODE=0775 \
    ACCEPT_EULA=Y \
    OPENSSL_CONF=/etc/ssl/openssl.cnf

# Rename the default user and the associated homedir
    RUN usermod -l ${CT_USER} ubuntu \
    && groupmod -n ${CT_USER} ubuntu \
    && usermod -d /home/${CT_USER} -m ${CT_USER} \
    && echo "${CT_USER}:${CT_USER}" | chpasswd

## Appending the option statement to the openssl config file
## ensures that opensslv3 is able to connect to hosts using older versions.
RUN echo "Options = UnsafeLegacyRenegotiation" | tee -a ${OPENSSL_CONF}

ENV HOME=/home/${CT_USER}

WORKDIR ${HOME}

# Add CRAN repository for R and install R base packages
# RUN echo "deb https://cloud.r-project.org/bin/linux/ubuntu noble-cran40/" > \
#     /etc/apt/sources.list.d/cran40.list \
#     && apt-key adv --keyserver keyserver.ubuntu.com \
#         --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 \
#     && apt-get update \
#     && apt-get install -y --no-install-recommends \
#         r-base \
#         r-base-dev \
#     && apt-get clean \
#     && mkdir -p /usr/local/lib/R/etc/ \
#     && mkdir -p --mode ${CT_FMODE} ${HOME}/R/utils \
#     && mkdir -p --mode ${CT_FMODE} ${HOME}/R/site-library \
#     && echo "R_LIBS_SITE=${R_LIBS_SITE-'${HOME}/R/site-library:/usr/local/lib/R/site-library:/usr/lib/R/site-library:/usr/lib/R/library'}" \
#         >> ${HOME}/.Renviron \
#     && chown -R ${CT_UID}:${CT_GID} ${HOME}/.Renviron \
#     && echo \
#         "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl')" \
#         >> /usr/local/lib/R/etc/Rprofile.site 

# Use rig to install a system-wide R.
RUN curl -LsSf https://r-lib.github.io/rig/install.sh | sh \
    && $HOME/.local/bin/rig add release \
    && mkdir -p ${HOME}/R/utils

COPY rpkgs.csv ${HOME}/R/utils/rpkgs.csv
COPY Rpkg_install.R ${HOME}/R/utils/Rpkg_install.R

WORKDIR ${HOME}
USER ${CT_USER}

ENV JUPYTERLAB_DIR=${HOME}/.jupyter/lab

USER root

# Install RStudio-Server and the IRKernel package
RUN wget -q $RSTUDIO_URL \
    && gdebi -n rstudio-server-*.deb \
    && rm rstudio-server-*.deb

COPY pip.conf .config/pip/pip.conf
ENV PATH=${HOME}/.local/bin:${HOME}/.TinyTeX/bin/x86_64-linux:${PATH} \
    RSESSION_PROXY_RSTUDIO_1_4=true \
    R_LIBS_USER=${HOME}/R/site-library

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal \
    && chown -R ${CT_UID}:${CT_GID} ${HOME}/.cargo \
    && chown -R ${CT_UID}:${CT_GID} ${HOME}/.rustup
# RUN chown -R ${CT_UID}:${CT_GID} ${HOME}/R

# jupyter port
EXPOSE 8888

# Add local files as late as possible to avoid cache busting
COPY start.sh /usr/local/bin/
COPY start-notebook.sh /usr/local/bin/
COPY start-singleuser.sh /usr/local/bin/
COPY start-jupyterlab.sh /usr/local/bin/
COPY fonts.zip /usr/local/share/fonts
RUN chown -R ${CT_UID}:${CT_GID} ${HOME} \
    && unzip /usr/local/share/fonts/fonts.zip -d /usr/local/share/fonts \
    && rm /usr/local/share/fonts/fonts.zip \
    && fc-cache -f \
    && mkdir ${HOME}/quarto \
    && chown -hR ${CT_UID}:${CT_GID} ${HOME}

# Install ripgrep
# ripgrep, a modern replacement for pgrep
RUN curl -fL --retry 5 --retry-delay 2 -o /tmp/ripgrep.deb \
    "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep_${RIPGREP_VERSION}-1_amd64.deb" && \
    sudo dpkg -i /tmp/ripgrep.deb && \
    rm -f /tmp/ripgrep.deb  

# Install gopass, a Git/GPG-backed CLI secrets manager (git and gnupg2 are
# already installed above); users run `gopass init` at container runtime to
# create/import their own GPG key and password store, which is not baked
# into the image.
RUN curl -fL --retry 5 --retry-delay 2 -o /tmp/gopass.deb \
    "https://github.com/gopasspw/gopass/releases/download/v${GOPASS_VERSION}/gopass_${GOPASS_VERSION}_linux_amd64.deb" && \
    dpkg -i /tmp/gopass.deb && \
    rm -f /tmp/gopass.deb

USER ${CT_USER}

RUN mkdir -p ${HOME}/.config/gopass ${HOME}/.bash_completion.d \
    && gopass completion bash > ${HOME}/.bash_completion.d/gopass \
    && echo '[ -f ~/.bash_completion.d/gopass ] && source ~/.bash_completion.d/gopass' >> ${HOME}/.bashrc

# Install nvm to enable runtime installation of Node.js, which is required by 
# JupyterLab
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash
# To install Node.js, uncomment the following command before building the image.
# This will install the latest LTS version of Node.js and set it as the default.
# npm ships bundled with each Node release, so it lags the latest npm release;
# upgrade it explicitly after selecting the Node version.
RUN bash -c ". ${HOME}/.nvm/nvm.sh && nvm install --lts && nvm use --lts && nvm alias default node && npm install -g npm@latest && nvm cache clear"

# Install uv, a tool for managing multiple versions of Python
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && echo 'eval "$(uv generate-shell-completion bash)"' >> ${HOME}/.bashrc

# Install non-standard utilities.
# Micro text editor to ~/.config/micro
RUN mkdir -p ${HOME}/.config/micro && \
    curl https://getmic.ro | bash && \
    mv micro ${HOME}/.config/micro && \
    # eza, a modern replacement for ls
    mkdir -p ${HOME}/.config/eza && \
    wget -qc https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz -O - | tar xz -C ${HOME}/.config/eza && \
    # fzf, a command-line fuzzy finder
    mkdir -p ${HOME}/.config/fzf && \
    curl -fL --retry 5 --retry-delay 2 \
    -o /tmp/fzf.tar.gz \
    "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz" && \
    tar -xzf /tmp/fzf.tar.gz -C "${HOME}/.config/fzf" && \
    rm -f /tmp/fzf.tar.gz && \
    # zoxide, a modern replacement for cd an soft link the installed utilities to ~/.local/bin
    curl -sS https://webinstall.dev/zoxide | bash && \
    # Soft link the installed utilities to ~/.local/bin
    mkdir -p ${HOME}/.local/bin && \
    ln -s ${HOME}/.config/micro/micro ${HOME}/.local/bin && \
    ln -s ${HOME}/.config/eza/eza ${HOME}/.local/bin && \
    ln -s ${HOME}/.config/fzf/fzf ${HOME}/.local/bin

COPY .bashrc ${HOME}/.bashrc-eza
RUN cat ${HOME}/.bashrc-eza >> ${HOME}/.bashrc \
    && rm -f ${HOME}/.bashrc-eza

ARG VCS_URL=${VCS_URL}
ARG VCS_REF=${VCS_REF}
ARG BUILD_DATE=${BUILD_DATE}

# Add image metadata
LABEL org.label-schema.license="https://opensource.org/licenses/MIT" \
    org.label-schema.vendor="Dockerfile provided by Mark Coggeshall" \
    org.label-schema.name="Scientific Python Foundation" \
    org.label-schema.description="Docker image including a foundational scientific Python stack based on Python 3 and R." \
    org.label-schema.vcs-url=${VCS_URL} \
    org.label-schema.vcs-ref=${VCS_REF} \
    org.label-schema.build-date=${BUILD_DATE} \
    maintainer="Mark Coggeshall <mark.coggeshall@gmail.com>"

WORKDIR ${HOME}/work
CMD [ "/bin/bash" ]
