# gnu-octave/docker

# Please follow docker best practices
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

# Provides a base Ubuntu image with the latest stable GNU Octave
# <https://www.octave.org> installed.

FROM  ubuntu:18.04 AS ubuntu1804build
LABEL maintainer="Kai T. Ohlhus <k.ohlhus@gmail.com>"

ENV LAST_UPDATED=2020-10-01

# Install security updates and required packages.

RUN apt-get --yes update  && \
    apt-get --yes upgrade && \
    apt-get --yes install \
      autoconf \
      automake \
      bison \
      clang \
      cmake \
      dbus \
      epstool \
      flex \
      g++ \
      gcc \
      gfortran \
      git \
      gnuplot \
      gperf \
      gzip \
      icoutils \
      less \
      libblas-dev \
      libcurl4-gnutls-dev \
      liblapack-dev \
      libpcre3-dev \
      libfftw3-dev \
      libfltk1.3-dev \
      libfontconfig1-dev \
      libfreetype6-dev \
      libgl1-mesa-dev \
      libgl2ps-dev \
      libgmp-dev \
      libgpgme11-dev \
      libgraphicsmagick++1-dev \
      libhdf5-serial-dev \
      libosmesa6-dev \
      libqhull-dev \
      libqscintilla2-qt5-dev \
      libqt5opengl5-dev \
      libreadline-dev \
      librsvg2-bin \
      libseccomp-dev \
      libssl-dev \
      libsndfile1-dev \
      libtool \
      libxft-dev \
      lpr \
      make \
      mercurial \
      openjdk-11-jdk \
      perl \
      pkg-config \
      portaudio19-dev \
      pstoedit \
      qtbase5-dev \
      qttools5-dev \
      qttools5-dev-tools \
      tar \
      texinfo \
      texlive \
      texlive-generic-recommended \
      transfig \
      unzip \
      wget \
      zlib1g-dev \
      zip                        && \
    apt-get --yes clean          && \
    apt-get --yes autoremove


# Install OpenBLAS

RUN OPENBLAS_VERSION=0.3.11 && \
    mkdir -p /tmp/build     && \
    cd       /tmp/build     && \
    wget "https://github.com/xianyi/OpenBLAS/archive/v${OPENBLAS_VERSION}.tar.gz" && \
    tar -xf    v${OPENBLAS_VERSION}.tar.gz  && \
    cd OpenBLAS-${OPENBLAS_VERSION}         && \
    make -j8             \
      BINARY=64          \
      INTERFACE64=1      \
      DYNAMIC_ARCH=1     \
      CONSISTENT_FPCSR=1 \
      USE_THREAD=1       \
      USE_OPENMP=1       \
      NUM_THREADS=256 && \
    make install         \
      PREFIX=/usr     && \
    rm -rf /tmp/build


# Install SuiteSparse

RUN SUITE_SPARSE_VERSION=5.7.2  && \
    mkdir -p /tmp/build         && \
    cd       /tmp/build         && \
    wget "https://github.com/DrTimothyAldenDavis/SuiteSparse/archive/v${SUITE_SPARSE_VERSION}.tar.gz"  && \
    tar -xf       v${SUITE_SPARSE_VERSION}.tar.gz  && \
    cd SuiteSparse-${SUITE_SPARSE_VERSION}         && \
    make -j8 library                           \
      LAPACK=                                  \
      BLAS=-lopenblas                          \
      UMFPACK_CONFIG=-D'LONGBLAS=long'         \
      CHOLMOD_CONFIG=-D'LONGBLAS=long'         \
      LDFLAGS='-L/tmp/build/SuiteSparse-'"${SUITE_SPARSE_VERSION}"'/lib'  && \
    make install                               \
      INSTALL=/usr                             \
      INSTALL_INCLUDE=/usr/include/suitesparse \
      INSTALL_DOC=/tmp/build/doc               \
      LAPACK=                                  \
      BLAS=-lopenblas                          \
      LDFLAGS='-L/tmp/build/SuiteSparse-'"${SUITE_SPARSE_VERSION}"'/lib'  && \
    rm -rf /tmp/build


# Install ARPACK NG

RUN ARPACK_NG_VERSION=3.7.0 && \
    mkdir -p /tmp/build     && \
    cd       /tmp/build     && \
    wget "https://github.com/opencollab/arpack-ng/archive/${ARPACK_NG_VERSION}.tar.gz" && \
    tar -xf      ${ARPACK_NG_VERSION}.tar.gz  && \
    cd arpack-ng-${ARPACK_NG_VERSION}         && \
    ./bootstrap                 && \
    ./configure                    \
      --prefix=/usr                \
      --libdir=/usr/lib            \
      --with-blas='-lopenblas'     \
      --with-lapack=''             \
      INTERFACE64=1                \
      LT_SYS_LIBRARY_PATH=/usr/lib \
      LDFLAGS='-L/usr/lib'      && \
    make -j8                    && \
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib  && \
    make check    && \
    make install  && \
    rm -rf /tmp/build


# Install QRUPDATE

RUN QRUPDATE_VERSION=1.1.2 && \
    mkdir -p /tmp/build    && \
    cd       /tmp/build    && \
    wget "http://downloads.sourceforge.net/project/qrupdate/qrupdate/1.2/qrupdate-${QRUPDATE_VERSION}.tar.gz"  && \
    tar -xf qrupdate-${QRUPDATE_VERSION}.tar.gz       && \
    cd      qrupdate-${QRUPDATE_VERSION}              && \
    make -j8                                             \
      PREFIX=/usr                                        \
      LAPACK=""                                          \
      BLAS="-lopenblas"                                  \
      FFLAGS="-L/usr/lib -fdefault-integer-8"         && \
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib  && \
    make test                                            \
      PREFIX=/usr                                        \
      LAPACK=""                                          \
      BLAS="-lopenblas"                                  \
      FFLAGS="-L/usr/lib -fdefault-integer-8"         && \
    make install                                         \
      PREFIX=/usr                                        \
      LAPACK=""                                          \
      BLAS="-lopenblas"                                  \
      FFLAGS="-L/usr/lib -fdefault-integer-8"         && \
    rm -rf /tmp/build


# Install GLPK

RUN GLPK_VERSION=4.65    && \
    mkdir -p /tmp/build  && \
    cd       /tmp/build  && \
    wget "https://ftp.gnu.org/gnu/glpk/glpk-${GLPK_VERSION}.tar.gz"  && \
    tar -xf glpk-${GLPK_VERSION}.tar.gz  && \
    cd      glpk-${GLPK_VERSION}         && \
    ./configure             \
      --with-gmp            \
      --prefix=/usr         \
      --libdir=/usr/lib  && \
    make -j8             && \
    make check           && \
    make install         && \
    rm -rf /tmp/build


# Install Sundials

RUN SUNDIALS_VERSION=5.4.0  && \
    mkdir -p /tmp/build     && \
    cd       /tmp/build     && \
    wget -q "https://computation.llnl.gov/projects/sundials/download/sundials-${SUNDIALS_VERSION}.tar.gz" && \
    tar -xf sundials-${SUNDIALS_VERSION}.tar.gz  && \
    cd      sundials-${SUNDIALS_VERSION}         && \
    mkdir build  && \
    cd    build  && \
    cmake                                          \
      -DEXAMPLES_ENABLE_C=OFF                      \
      -DKLU_ENABLE=ON                              \
      -DKLU_INCLUDE_DIR=/usr/include/suitesparse   \
      -DKLU_LIBRARY_DIR=/usr/lib/x86_64-linux-gnu  \
      -DBUILD_ARKODE=OFF                           \
      -DBUILD_CVODE=OFF                            \
      -DBUILD_CVODES=OFF                           \
      -DBUILD_IDA=ON                               \
      -DBUILD_IDAS=OFF                             \
      -DBUILD_KINSOL=OFF                           \
      -DBUILD_CPODES=OFF                           \
      -DCMAKE_INSTALL_PREFIX=/usr                  \
      ..              && \
    make -j4          && \
    make install      && \
    rm -rf /tmp/build


FROM ubuntu1804build AS octave520build

RUN OCTAVE_VERSION=5.2.0  && \
    mkdir -p /tmp/build   && \
    cd       /tmp/build   && \
    wget "https://ftpmirror.gnu.org/octave/octave-${OCTAVE_VERSION}.tar.gz"  && \
    tar -xf octave-${OCTAVE_VERSION}.tar.gz  && \
    cd      octave-${OCTAVE_VERSION}         && \
    ./configure                                 \
      F77_INTEGER_8_FLAG='-fdefault-integer-8'  \
      --prefix=/usr                             \
      --enable-64                               \
      --with-blas='-lopenblas'               && \
    make -j8      && \
    make check    && \
    make install  && \
    rm -rf /tmp/build


FROM octave520build AS octave520

RUN apt-get --yes remove \
      bison \
      flex \
      icoutils \
      libcurl4-gnutls-dev \
      libreadline-dev \
      libsndfile1-dev \
      portaudio19-dev \
      qtbase5-dev \
      qttools5-dev \
      qttools5-dev-tools \
      texlive \
      texlive-generic-recommended && \
    apt-get --yes install \
      fonts-ipafont-gothic \
      fonts-noto-color-emoji \
      info \
      libcurl3-gnutls \
      libgnutls28-dev \
      libmpfr-dev \
      libportaudio2 \
      libqt5gui5 \
      libqt5help5 \
      libqt5network5 \
      libqt5printsupport5 \
      libqt5widgets5 \
      libqt5xml5 \
      libqscintilla2-qt5-13 \
      libreadline7 \
      libsndfile1 \
      python3-pip                && \
    # Install required python packages
    #   - sympy, see https://savannah.gnu.org/bugs/?58491
    pip3 install --upgrade --no-cache-dir \
      sympy==1.5.1               && \
    apt-get --yes remove            \
      python3-pip                && \
    apt-get --yes clean          && \
    apt-get --yes autoremove     && \
    rm -Rf /var/lib/apt/lists/*  && \
    rm -Rf /usr/share/doc

ENV LC_ALL=C

CMD ["octave-cli"]
