#!/bin/bash

if [ $# -lt 1 ]; then
       echo "USAGE: $0 [-h] <tracepoint>"
       exit 1
elif [ $# -eq 2 ] && [[ $1 ==  "-h" ]]; then
	func=$2
	sudo  bpftrace -e "$func {@[kstack] = count();}"
else
	func=$1
	sudo bpftrace -e "$func { printf(\"%s\n\", kstack());}"
fi
