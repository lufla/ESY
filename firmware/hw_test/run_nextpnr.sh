#!/usr/bin/env bash

SRC_DIR=RTL
TOP=csi_top
NETLIST=netlist

nextpnr-himbaechel \
	--device=CCGM1A1 \
	--json ${NETLIST}.json \
	-o ccf=${SRC_DIR}/${TOP}.ccf \
	-o out=impl.txt \
	--router router2 \
	--gui