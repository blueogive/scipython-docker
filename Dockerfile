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
FROM ubuntu:focal-20200916 AS builder00

ENV DEBIAN_FRONTEND=noninteractive \
    FONT_LOCAL=/usr/local/share/fonts \
    LC_ALL="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    SHELL=/bin/bash \
    CT_USER=docker \
    CT_UID=1000 \
    CT_GID=1000 \
    CT_FMODE=0775

ENV HOME=/home/${CT_USER}

RUN useradd --create-home --uid ${CT_UID} \
    --user-group \
    --shell ${SHELL} --home-dir ${HOME} \
    --password ${CT_USER} --groups sudo,users ${CT_USER}

RUN apt-get update --fix-missing \
    && apt-get install -y --no-install-recommends \
        bzip2 \
        ca-certificates \
        curl \
        fontconfig \
        gdebi-core \
        git \
        gnupg2 \
        libapparmor1 \
        libclang-dev \
        libssl-dev \
        locales \
        lsb-release \
        psmisc \
        wget \
        build-essential \
        gfortran \
        default-jdk \
        dpkg \
        # Linux system packages that are dependencies of R packages
        libxml2-dev \
        libcurl4-gnutls-dev \
        liblapack-dev \
        libgeos-dev \
        libproj-dev \
        libcairo2-dev \
        unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY fonts.zip ${FONT_LOCAL}

WORKDIR ${FONT_LOCAL}

## Setup the locale
RUN unzip fonts.zip \
    && rm fonts.zip \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=en_US.UTF-8 \
RUN git clone --branch release --depth 1 \
    'https://github.com/adobe-fonts/source-code-pro.git' \
    "${FONT_LOCAL}/adobe-fonts/source-code-pro" \
    # XeTeX gets hung up by these WOFF files, if they are present.
    # Looks like a bug.
    && rm -rf ${FONT_LOCAL}/adobe-fonts/source-code-pro/WOFF
RUN fc-cache -f -v ${FONT_LOCAL}

FROM builder00 AS pandoc

ENV PANDOC_TEMPLATES_VERSION=2.10.1

## Install pandoc-templates.
RUN mkdir -p /opt/pandoc/templates \
  && cd /opt/pandoc/templates \
  && wget -q https://github.com/jgm/pandoc-templates/archive/${PANDOC_TEMPLATES_VERSION}.tar.gz \
  && tar xzf ${PANDOC_TEMPLATES_VERSION}.tar.gz \
  && rm ${PANDOC_TEMPLATES_VERSION}.tar.gz

FROM builder00 AS msft

## Install Microsoft and Postgres ODBC drivers and SQL commandline tools
RUN curl -o microsoft.asc https://packages.microsoft.com/keys/microsoft.asc \
    && apt-key add microsoft.asc \
    && rm microsoft.asc \
    && curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y --no-install-recommends \
        msodbcsql17 \
        mssql-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm /etc/apt/sources.list.d/mssql-release.list

FROM builder00 AS conda

RUN wget --quiet \
    https://repo.anaconda.com/miniconda/Miniconda3-py38_4.8.3-Linux-x86_64.sh \
    -O /root/miniconda.sh
RUN if [ "`md5sum /root/miniconda.sh | cut -d\  -f1`" = "d63adf39f2c220950a063e0529d4ff74" ]; then \
        /bin/bash /root/miniconda.sh -b -p /opt/conda; fi \
    && rm /root/miniconda.sh \
    && /opt/conda/bin/conda clean -atipsy \
    && ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh 

# Add a script that we will use to correct permissions after running certain commands
ADD fix-permissions /usr/local/bin/fix-permissions

RUN fix-permissions ${CONDA_DIR}

ARG CONDA_ENV_FILE=${CONDA_ENV_FILE}
COPY ${CONDA_ENV_FILE} ${CONDA_ENV_FILE}
RUN /opt/conda/bin/conda update -n base -c defaults conda \
    && /opt/conda/bin/conda env update -n base --file ${CONDA_ENV_FILE} \
    && /opt/conda/bin/conda install conda-build -y \
    && /opt/conda/bin/conda build purge-all \
    && /opt/conda/bin/conda config --add channels conda-forge \
    && /opt/conda/bin/conda config --set channel_priority strict \
    && /opt/conda/bin/conda clean -atipsy \
    && rm ${CONDA_ENV_FILE}

RUN mkdir -p ${HOME}/.jupyter/lab
ENV JUPYTERLAB_DIR=${HOME}/.jupyter/lab \
    PATH=/opt/conda/bin:${PATH}
RUN jupyter labextension install @jupyterlab/hub-extension \
    && npm cache clean --force \
    && jupyter notebook --generate-config \
    && jupyter lab build \
    && rm -rf ${CONDA_DIR}/share/jupyter/lab/staging \
    && rm -rf ${HOME}/.cache/yarn \
    && fix-permissions ${CONDA_DIR} \
    && fix-permissions ${HOME} 

# USER ${CT_USER}

RUN echo ". /opt/conda/etc/profile.d/conda.sh" >> ${HOME}/.bashrc && \
    echo "conda activate base" >> ${HOME}/.bashrc && \
    mkdir ${HOME}/work
SHELL [ "/bin/bash", "--login", "-c"]
ARG PIP_REQ_FILE=${PIP_REQ_FILE}
COPY ${PIP_REQ_FILE} ${PIP_REQ_FILE}
RUN source ${HOME}/.bashrc \
    && conda activate base \
    && git clone https://github.com/blueogive/pyncrypt.git \
    && pip install --user --no-cache-dir --disable-pip-version-check pyncrypt/ \
    && rm -rf pyncrypt \
    && git clone https://github.com/blueogive/py_qualtrics_api.git \
    && pip install --user --no-cache-dir --disable-pip-version-check py_qualtrics_api/ \
    && rm -rf py_qualtrics_api \
    && git clone https://github.com/jupyterhub/jupyter-rsession-proxy.git \
    && pip install --user --no-cache-dir --disable-pip-version-check jupyter-rsession-proxy/ \
    && rm -rf jupyter-rsession-proxy \
    && pip install --user --no-cache-dir --disable-pip-version-check \
      -r ${PIP_REQ_FILE} \
    && rm ${PIP_REQ_FILE} \
    && mkdir -p .config/pip \
    && fix-permissions ${HOME}/work \
    && fix-permissions ${HOME}/.local \
    && touch ${HOME}/.gitconfig \
    && mkdir ${HOME}/.ssh \
    && chmod 0700 ${HOME}/.ssh \
    && chown ${CT_UID}:${CT_GID} ${HOME}/.ssh \
    && chown ${CT_UID}:${CT_GID} ${HOME}/.gitconfig
COPY pip.conf .config/pip/pip.conf
COPY jupyter_notebook_config.py /etc/jupyter/
RUN fix-permissions /etc/jupyter/

FROM builder00 AS gnur

RUN echo "deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/" > \
    /etc/apt/sources.list.d/cran40.list \
    && apt-key adv --keyserver keyserver.ubuntu.com \
        --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        r-base \
        r-base-dev \
        littler \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /usr/local/lib/R/etc/ \
    && echo \
        "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl')" \
        >> /usr/local/lib/R/etc/Rprofile.site

COPY rpkgs.csv rpkgs.csv
COPY Rpkg_install.R Rpkg_install.R
RUN mkdir -p --mode ${CT_FMODE} ${HOME}/.checkpoint
RUN Rscript Rpkg_install.R
RUN rm rpkgs.csv Rpkg_install.R \
    && mkdir -p ${HOME}/R/x86_64-pc-linux-gnu-library/4.0 \
    && chown -R ${CT_UID}:${CT_GID} ${HOME}/.checkpoint \
    && chown -R ${CT_USER}:${CT_GID} ${HOME}/bin \
    && chown -R ${CT_USER}:${CT_GID} ${HOME}/.TinyTeX \
    && chown -R ${CT_USER}:${CT_GID} ${HOME}/R/x86_64-pc-linux-gnu-library/4.0

# Add a script that we will use to correct permissions after running certain commands
ADD fix-permissions /usr/local/bin/fix-permissions

RUN fix-permissions /home/${CT_USER}

RUN apt-get update --fix-missing \
    && apt-get install -y --no-install-recommends \
        sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV RSTUDIO_VERSION=1.2.5033
ENV RSTUDIO_URL="https://download2.rstudio.org/server/bionic/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb"

# Install RStudio-Server and the IRKernel package
RUN wget -q $RSTUDIO_URL
RUN dpkg -i rstudio-server-*-amd64.deb
RUN rm rstudio-server-*-amd64.deb

FROM ubuntu:focal-20200916 AS final

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update --fix-missing \
    && apt-get install -y --no-install-recommends \
        build-essential \
        bzip2 \
        ca-certificates \
        curl \
        git \
        gnupg2 \
        gosu \
        locales \
        make \
        openssh-client \
        sudo \
        wget \
        default-jdk \
        dpkg \
        odbc-postgresql \
        pandoc \
        pandoc-citeproc \
        unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV LC_ALL="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    SHELL=/bin/bash \
    CT_USER=docker \
    CT_UID=1000 \
    CT_GID=1000 \
    CT_FMODE=0775

RUN echo "${LC_ALL} UTF-8" >> /etc/locale.gen \
    && locale-gen en_US.utf8 \
    && /usr/sbin/update-locale LANG=${LANG}

ENV HOME=/home/${CT_USER}
ENV PATH=/opt/conda/bin:/opt/mssql-tools/bin:/usr/lib/rstudio-server/bin:${HOME}/.local/bin:${HOME}/.TinyTeX/bin/x86_64-linux:${PATH}

RUN useradd --create-home --uid ${CT_UID} \
    --user-group \
    --shell ${SHELL} --home-dir ${HOME} \
    --password ${CT_USER} --groups sudo,users ${CT_USER} \
    && echo "deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/" > \
    /etc/apt/sources.list.d/cran40.list \
    && apt-key adv --keyserver keyserver.ubuntu.com \
        --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9

COPY --from=pandoc /opt/pandoc /opt/pandoc
COPY --from=msft /opt/microsoft /opt/microsoft
COPY --from=msft /opt/mssql-tools /opt/mssql-tools
COPY --from=conda /opt/conda /opt/conda
COPY --from=gnur /home/${CT_USER} /home/${CT_USER}
COPY --from=conda /home/${CT_USER}/.jupyter /home/${CT_USER}/.jupyter
COPY --from=conda /home/${CT_USER}/.local /home/${CT_USER}/.local
COPY --from=conda /home/${CT_USER}/.gitconfig /home/${CT_USER}/.gitconfig
COPY --from=conda /home/${CT_USER}/.ssh /home/${CT_USER}/.ssh
COPY --from=conda /home/${CT_USER}/.config /home/${CT_USER}/.config
COPY --from=conda /usr/local /usr/local
COPY --from=builder00 /etc/locale.gen /etc/locale.gen
COPY --from=gnur /usr/lib/R /usr/lib/R
COPY --from=gnur /usr/local/lib/R /usr/local/lib/R
COPY --from=gnur /usr/lib/rstudio-server /usr/lib/rstudio-server
COPY --from=gnur /usr/lib/libR.so /usr/lib/libR.so
COPY --from=gnur /usr/bin/R /usr/bin/R
COPY --from=gnur /usr/share/R /usr/share/R
COPY --from=gnur /usr/bin/Rscript /usr/bin/Rscript
COPY --from=gnur /usr/lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu
COPY --from=gnur /lib /lib
COPY --from=gnur /etc/alternatives /etc/alternatives
COPY --from=gnur /etc/R /etc/R
COPY --from=gnur /etc/rstudio /etc/rstudio
COPY --from=gnur /etc/ld.so.conf /etc/ld.so.conf
COPY --from=gnur /etc/ld.so.conf.d /etc/ld.so.conf.d
COPY --from=builder00 /usr/local/share/fonts /usr/local/share/fonts

RUN fc-cache -f -v
RUN mkdir -p ${HOME}/.pandoc
RUN ln -s /opt/pandoc/templates ${HOME}/.pandoc/templates
RUN chown -R ${CT_USER}:${CT_GID} ${HOME}/.pandoc
RUN echo "R_LIBS_SITE=${R_LIBS_SITE-'/usr/local/lib/R/site-library:/usr/lib/R/site-library:/usr/lib/R/library'}" \
    >> ${HOME}/.Renviron
RUN chown ${CT_UID}:${CT_GID} ${HOME}/.Renviron

RUN ldconfig
# RUN Rscript -e "install.packages('IRkernel')"
# RUN Rscript -e "IRkernel::installspec(user=FALSE)"
RUN fix-permissions ${HOME}/.local
RUN chown ${CT_UID}:${CT_GID} ${HOME}/.local

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

# jupyter port
EXPOSE 8888
# dagit port
EXPOSE 3000

# Add local files as late as possible to avoid cache busting
COPY start.sh /usr/local/bin/
COPY start-notebook.sh /usr/local/bin/
COPY start-singleuser.sh /usr/local/bin/

WORKDIR /home/docker/work
CMD [ "/bin/bash" ]
