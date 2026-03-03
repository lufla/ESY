./run_yosys.sh
./run_nextpnr.sh
./run_gmpack.sh
openFPGALoader --cable gatemate_pgm --busdev-num $1 impl.bit
