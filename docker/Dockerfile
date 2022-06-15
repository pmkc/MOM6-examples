ARG BASE=gcr.io/deeplearning-platform-release/base-cpu
# ARG BASE=jupyter/scipy-notebook

FROM $BASE

RUN sudo apt-get update && sudo apt-get install -y csh make gfortran openmpi-bin libopenmpi-dev libnetcdf-dev libnetcdff-dev netcdf-bin
RUN rm /bin/sh && ln -sf /usr/bin/bash /bin/sh

WORKDIR /opt

ADD compile.sh .

RUN bash -ex compile.sh

RUN chmod -R a+rX MOM6-examples
RUN chmod -R a+x MOM6-examples/build/intel/*/repro/MOM6

# Validate
RUN cd MOM6-examples/ocean_only/double_gyre/ \
 && mkdir -p RESTART \
 && MOM6

WORKDIR /

RUN conda install -y ipywidgets
