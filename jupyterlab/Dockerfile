# gnu-octave/docker

# Please follow docker best practices
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

# Provides GNU Octave <https://www.octave.org> based on Ubuntu 18.04.

FROM  gnuoctave/octave:6.1.0 AS build
LABEL maintainer="Kai T. Ohlhus <k.ohlhus@gmail.com>"

ENV LAST_UPDATED=2021-02-01

# Install JupyterLab

RUN chmod 777 /tmp        && \
    apt-get --yes update  && \
    apt-get --yes install    \
      locales                \
      python3-pip            \
      sudo                && \
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
    apt-get --yes remove            \
      python3-pip                && \
    apt-get --yes clean          && \
    apt-get --yes autoremove     && \
    rm -Rf /var/lib/apt/lists/*  && \
    rm -Rf /usr/share/doc        && \
    jupyter notebook --generate-config && \
    jupyter lab clean

## From https://github.com/jupyter/docker-stacks/tree/master/base-notebook
## (2021-02-10)

ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"

# Fix DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Configure environment
ENV SHELL=/bin/bash \
    NB_USER=$NB_USER \
    NB_UID=$NB_UID \
    NB_GID=$NB_GID \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    HOME=/home/$NB_USER

ADD https://github.com/krallin/tini/releases/download/v0.19.0/tini /tini
RUN chmod +x /tini

# Copy a script that we will use to correct permissions after running certain commands
COPY fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions

# Create NB_USER with name jovyan user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    chmod g+w /etc/passwd && \
    fix-permissions $HOME

USER $NB_UID

EXPOSE 8888

# Configure container startup
ENTRYPOINT ["/tini", "-g", "--"]
CMD ["start-notebook.sh"]

# Copy local files as late as possible to avoid cache busting
COPY start.sh start-notebook.sh start-singleuser.sh /usr/local/bin/
# Currently need to have both jupyter_notebook_config and jupyter_server_config to support classic and lab
COPY jupyter_notebook_config.py /etc/jupyter/

# Fix permissions on /etc/jupyter as root
USER root

# Prepare upgrade to JupyterLab V3.0 #1205
RUN sed -re "s/c.NotebookApp/c.ServerApp/g" \
    /etc/jupyter/jupyter_notebook_config.py > /etc/jupyter/jupyter_server_config.py

RUN fix-permissions /etc/jupyter/

# Switch back to jovyan to avoid accidental container runs as root
USER $NB_UID

WORKDIR $HOME

