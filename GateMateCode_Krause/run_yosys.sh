#!/usr/bin/env bash

SRC_DIR=RTL
TOP=csi_top
NETLIST=netlist
LOGFILE=yosys.log

yosys \
    -ql "$LOGFILE" \
    -p "
        read_verilog_file_list -f files.f;
        synth_gatemate \
            -top ${TOP} \
            -luttree \
            -nomx8;
        write_json ${NETLIST}.json;
        write_verilog ${NETLIST}.v
    "
