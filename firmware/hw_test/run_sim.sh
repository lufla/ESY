#!/usr/bin/env bash

SRC_DIR=RTL
SIM=csi_top
TOP=netlist
NETLIST=netlist
LOGFILE=yosys.log

iverilog \
    -o Sim/${TOP}.vvp \
    ${TOP}.v \
    Sim/Sim/Testbenches/Rx_sim/${SIM}_tb.v \
    Sim/Sim/cells_sim.v \
    Sim/Sim/cells_bb.v
vvp -N Sim/${TOP}.vvp