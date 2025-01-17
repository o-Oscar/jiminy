#!/bin/bash

# Script for installing pre-compiled binaries of the required dependencies through apt-get on Ubuntu

export DEBIAN_FRONTEND=noninteractive

# Determine if the script is being executed on Ubuntu
if [ -f /etc/lsb-release ]; then
    source /etc/lsb-release
    if [ "$DISTRIB_ID" != "Ubuntu" ] ; then
        echo "Not running on Ubuntu. Aborting..."
        exit 0
    fi
else
    echo "Not running on Ubuntu. Aborting..."
    exit 0
fi

# Get Python 3 executable
PYTHON_BIN="$(basename $(readlink $(which python3)))"

# Set SUDO_UID to 0 (root) if not defined, which may happen in docker container
if [ -z ${SUDO_UID+x} ]; then
    SUDO_UID=0;
fi

# Install Python 3 standard utilities
apt update && \
apt install -y sudo python3-setuptools python3-pip python3-tk && \
sudo -u $(id -nu "$SUDO_UID") python3 -m pip install --upgrade pip && \
sudo -u $(id -nu "$SUDO_UID") python3 -m pip install --upgrade wheel && \
sudo -u $(id -nu "$SUDO_UID") python3 -m pip install --upgrade "numpy>=1.16"

# Install Python 3 toolsuite for testing and documentation generation
sudo -u $(id -nu "$SUDO_UID") python3 -m pip install --upgrade setuptools auditwheel && \
sudo -u $(id -nu "$SUDO_UID") python3 -m pip install --upgrade flake8 pylint mypy types-toml && \
sudo -u $(id -nu "$SUDO_UID") python3 -m pip install --upgrade \
    pygments colorama sphinx sphinx_rtd_theme recommonmark nbsphinx breathe aafigure

# Install standard linux utilities
apt install -y gnupg curl wget build-essential cmake doxygen graphviz pandoc

# Install some additional dependencies
apt install -y libeigen3-dev libboost-all-dev liboctomap-dev

# Install OpenGL
apt install -y mesa-utils

# Install robotpkg tools suite
if ! [ -d "/opt/openrobots/lib/${PYTHON_BIN}/site-packages/" ] ; then
    # Add apt repository if necessary
    if ! grep -q "^deb .*robotpkg.openrobots.org" /etc/apt/sources.list.d/*; then
        sh -c "echo 'deb [arch=amd64] http://robotpkg.openrobots.org/packages/debian/pub ${DISTRIB_CODENAME} robotpkg' >> /etc/apt/sources.list.d/robotpkg.list" && \
        curl http://robotpkg.openrobots.org/packages/debian/robotpkg.key | apt-key add - && \
        apt update
    fi

    # apt-get must be used instead of apt to support wildcard in package name on Ubuntu 20
    apt-get install -y --allow-downgrades --allow-unauthenticated \
        robotpkg-octomap=1.9.0 robotpkg-urdfdom-headers=1.0.4 robotpkg-hpp-fcl=1.7.1 robotpkg-pinocchio=2.5.6 \
        robotpkg-qt5-osgqt=3.5.7r2 robotpkg-py3*-qt5-gepetto-viewer=4.12.0r2 robotpkg-py3*-qt5-gepetto-viewer-corba=5.6.0 \
        robotpkg-py3*-omniorbpy=4.2.4 robotpkg-py3*-eigenpy=2.6.2 robotpkg-py3*-hpp-fcl=1.7.1 robotpkg-py3*-pinocchio=2.5.6

    sudo -H -u $(id -nu "$SUDO_UID") bash -c " \
    echo 'export LD_LIBRARY_PATH=\"/opt/openrobots/lib:\${LD_LIBRARY_PATH}\"' >> \$HOME/.bashrc && \
    echo 'export PATH=\"\${PATH}:/opt/openrobots/bin\"' >> \$HOME/.bashrc && \
    mkdir -p \$HOME/.local/lib/${PYTHON_BIN}/site-packages && \
    touch \$HOME/.local/lib/${PYTHON_BIN}/site-packages/openrobots.pth && \
    echo /opt/openrobots/lib/${PYTHON_BIN}/site-packages/ > \$HOME/.local/lib/${PYTHON_BIN}/site-packages/openrobots.pth"
fi
