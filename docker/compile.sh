#!/usr/bin/bash

set -ex

sudo apt-get update && sudo apt-get install -y csh make gfortran openmpi-bin libopenmpi-dev libnetcdf-dev libnetcdff-dev netcdf-bin

git clone --recursive https://github.com/NOAA-GFDL/MOM6-examples

cd MOM6-examples

MKMF=$PWD/src/mkmf/bin/mkmf
LIST_PATHS=$PWD/src/mkmf/bin/list_paths
MAKE_TEMPLATE=$PWD/src/mkmf/templates/linux-ubuntu-xenial-gnu.mk

source /etc/os-release
if [[ $ID == ubuntu && $VERSION_ID = 20.04 ]]; then
  # https://github.com/mom-ocean/MOM5/pull/345/commits
  # Add new CCPDEFS on first line
  sed '1i CPPDEFS += -DHAVE_GETTID' $MAKE_TEMPLATE \
      > $PWD/src/mkmf/templates/linux-ubuntu-focal-gnu.mk
  MAKE_TEMPLATE=$PWD/src/mkmf/templates/linux-ubuntu-focal-gnu.mk
fi

# Compile FMS
mkdir -p build/intel/shared/repro
pushd build/intel/shared/repro/
rm -f path_names
$LIST_PATHS -l ../../../../src/FMS
$MKMF -t $MAKE_TEMPLATE -p libfms.a -c "-Duse_libMPI -Duse_netCDF" path_names
make NETCDF=3 REPRO=1 libfms.a -j
popd

# Compile MOM6 ocean only
mkdir -p build/intel/ocean_only/repro/
(cd build/intel/ocean_only/repro/; rm -f path_names; \
  ../../../../src/mkmf/bin/list_paths -l ./ ../../../../src/MOM6/{config_src/infra/FMS1,config_src/memory/dynamic_symmetric,config_src/drivers/solo_driver,config_src/external,src/{*,*/*}}/ ; \
  ../../../../src/mkmf/bin/mkmf -t ../../../../src/mkmf/templates/ncrc-intel.mk -o '-I../../shared/repro' -p MOM6 -l '-L../../shared/repro -lfms' path_names)
mkdir -p build/intel/ice_ocean_SIS2/repro/
pushd build/intel/ocean_only/repro/
rm -f path_names
$LIST_PATHS -l ./ ../../../../src/MOM6/{config_src/infra/FMS1,config_src/memory/dynamic_symmetric,config_src/drivers/solo_driver,config_src/external,src/{*,*/*}}/
$MKMF -t $MAKE_TEMPLATE -o '-I../../shared/repro' -p MOM6 -l '-L../../shared/repro -lfms' path_names
make NETCDF=3 REPRO=1 MOM6 -j
popd

# Compile MOM6 and SIS2
mkdir -p build/intel/ice_ocean_SIS2/repro/
pushd build/intel/ice_ocean_SIS2/repro/
rm -f path_names
$LIST_PATHS -l ./ ../../../../src/MOM6/config_src/{infra/FMS1,memory/dynamic_symmetric,drivers/FMS_cap,external} ../../../../src/MOM6/src/{*,*/*}/ ../../../../src/{atmos_null,coupler,land_null,ice_param,icebergs,SIS2,FMS/coupler,FMS/include}/
$MKMF -t $MAKE_TEMPLATE -o '-I../../shared/repro' -p MOM6 -l '-L../../shared/repro -lfms' -c '-Duse_AM3_physics -D_USE_LEGACY_LAND_' path_names
make NETCDF=3 REPRO=1 MOM6 -j
popd

# Optional installation
ln -sf $PWD/build/intel/ocean_only/repro/MOM6 /usr/local/bin/MOM6
ln -sf $PWD/build/intel/ice_ocean_SIS2/repro/MOM6 /usr/local/bin/MOM6_SIS2

# TODO: put data in /opt/MOM6-examples/.datasets

# Validate
# pushd ocean_only/double_gyre/ \
# mkdir -p RESTART \
# MOM6
