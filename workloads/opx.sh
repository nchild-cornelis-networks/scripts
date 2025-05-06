#!/bin/bash

if [ $# -lt 1 ] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "USAGE: $0 <hosts> [test, IMB-*]"
    exit 1
fi

test=IMB-MPI1
if [ $# -eq 2 ]; then
	test=$2
fi

hosts=$1

source /opt/intel/oneapi/setvars.sh

I_MPI_TUNING_BIN="" I_MPI_FABRICS=ofi LD_LIBRARY_PATH=/home/bcernohous/repos/libfabric-internal/install-main-debug/install/lib:$LD_LIBRARY_PATH  FI_OPX_UUID=$RANDOM FI_PROVIDER_PATH= MPIR_CVAR_CH4_OFI_ENABLE_AV_TABLE=0 FI_PROVIDER=opx MPIR_CVAR_CH4_OFI_ENABLE_MR_SCALABLE=1 MPIR_CVAR_CH4_OFI_ENABLE_RMA=1 MPIR_CVAR_CH4_OFI_ENABLE_ATOMICS=1 mpiexec --hosts $hosts -np 4 -ppn 2 -l $test -npmin 999 -v
