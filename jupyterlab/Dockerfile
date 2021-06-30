# gnu-octave/docker

# Please follow docker best practices
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

## Synchronized with https://github.com/jupyter/docker-stacks/tree/master/base-notebook

FROM  gnuoctave/octave:6.2.0
LABEL maintainer="Kai T. Ohlhus <k.ohlhus@gmail.com>"

ENV LAST_UPDATED=2021-06-01

# Install JupyterLab

USER root

RUN chmod 777 /tmp        && \
    apt-get --yes update  && \
    DEBIAN_FRONTEND="noninteractive" \
    apt-get --no-install-recommends --yes install \
      tini                && \
    # Install required python packages
    #   - sympy, see https://savannah.gnu.org/bugs/?58491
    pip3 install --upgrade --no-cache-dir \
      jupyterlab                    \
      octave_kernel                 \
      jupytext                      \
      jupyter-book                  \
      ghp-import                    \
      numpy                         \
      sympy==1.5.1                  \
      matplotlib                 && \
    apt-get --yes clean          && \
    apt-get --yes autoremove     && \
    rm -Rf /var/lib/apt/lists/*  && \
    jupyter notebook --generate-config && \
    jupyter lab clean

ARG NB_USER="jovyan"
ARG NB_UID="1111"
ARG NB_GID="100"

# Fix DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# FIXME: Hack around Octave executable enforcement (hopefully one day removed):
# https://github.com/Calysto/octave_kernel/blob/a613c29f40e22b1751164bca30df381799539f06/octave_kernel/kernel.py#L446-L461
RUN ln -s /usr/bin/octave /usr/bin/octave-cli-jupyter

# Configure environment
ENV SHELL=/bin/bash \
    NB_USER="${NB_USER}" \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    HOME=/home/$NB_USER \
    OCTAVE_EXECUTABLE=octave-cli-jupyter \
    JUPYTER_ENABLE_LAB=yes

USER ${NB_UID}

EXPOSE 8888

# Configure container startup
ENTRYPOINT ["tini", "-g", "--"]
CMD ["start-notebook.sh"]

# Copy local files as late as possible to avoid cache busting
COPY start.sh start-notebook.sh start-singleuser.sh /usr/local/bin/
# Currently need to have both jupyter_notebook_config and jupyter_server_config to support classic and lab
COPY jupyter_notebook_config.py /etc/jupyter/

# Fix permissions on /etc/jupyter as root
USER root

# Prepare upgrade to JupyterLab V3.0 #1205
RUN sed -re "s/c.NotebookApp/c.ServerApp/g" \
    /etc/jupyter/jupyter_notebook_config.py > /etc/jupyter/jupyter_server_config.py && \
    fix-permissions /etc/jupyter/

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}

WORKDIR "${HOME}"
