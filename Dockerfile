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
FROM ubuntu:bionic-20180821

USER root

RUN apt-get update --fix-missing && \
	apt-get install -y --no-install-recommends \
		wget \
		bzip2 \
		ca-certificates \
		curl \
		git \
		locales \
		curl && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

## Set environment variables
ENV LC_ALL=en_US.UTF-8 \
	LANG=en_US.UTF-8 \
	LANGUAGE=en_US.UTF-8 \
	PATH=/opt/conda/bin:$PATH \
	SHELL=/bin/bash \
	CT_USER=docker \
	CT_UID=1000 \
	CT_GID=100 \
	TINI_VERSION=v0.16.1
ENV HOME=/home/${CT_USER}

## Setup the locale
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& locale-gen ${LC_ALL} \
	&& /usr/sbin/update-locale LANG=${LANG}

RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-4.5.11-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda clean -tipsy && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \

ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini

## Set a default user. Available via runtime flag `--user docker`
## User should also have & own a home directory (e.g. for linked volumes to work properly).
RUN useradd ${CT_USER} \
	&& mkdir ${HOME} \
	&& chown ${CT_USER}:${CT_USER} ${HOME} \
	&& addgroup ${CT_USER} staff \
	&& chmod +x /usr/bin/tini

WORKDIR ${HOME}
USER ${CT_USER}
RUN echo ". /opt/conda/etc/profile.d/conda.sh" >> ${HOME}/.bashrc && \
    echo "conda activate base" >> ${HOME}/.bashrc && \
	mkdir ${HOME}/work

COPY requirements.txt requirements.txt
RUN /opt/conda/bin/conda install --file requirements.txt
RUN /opt/conda/bin/conda clean -tipsy
RUN pip install --no-cache-dir -r requirements.txt
RUN rm requirements.txt

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

ENTRYPOINT [ "/usr/bin/tini", "--" ]
CMD [ "/bin/bash" ]
