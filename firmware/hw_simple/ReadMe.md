# Short Description:

## Ich habe den Kram unter WSL mit Ubuntu 24.04 ausgeführt

Als erstes, die OSS CAD Suite herunterladen (bei mir X86 Linux): [Link](https://github.com/YosysHQ/oss-cad-suite-build/releases/)

Dann der Anleitung von hier [link](https://colognechip.com/programmable-logic/gatemate/gatemate-toolchain-quickstart/) folgen, also ab 'Installation Steps'.

Es wird im home Verzeichnis ein Ordner 'oss-cad-suite' erstellt. In den dann dieses Verzeichnis hier reinkopieren.

Ich habe zwei shell-skripte erstellt, 'run_yosys.sh' und 'run_sim.sh' (Ausführen mit "./xx.sh", ggf. mit "chmod +x filename.endung" ausführbar machen).
Diese führen eine Synthese durch und eine Simulation für den Testcode von Sven Krause.

Damit diese Scripte funktionieren muss nach Änderungen eine neue Fileliste erstellt werden:
find RTL -type f \( -name '*.v' -o -name '*.sv' \) > files.f

Dann müsst ihr noch "gtkwave csi_top_tb.vcd csi_top.gtkw" aufrufen um die Waveforms sehen zu können.
Das entspricht so dem, was wir in der Vorlesung hatten, nur mit OpenSource Tools statt Quartus.


# Programing of the FPGA:

## WSL Users only:

At First:
Install usbipd (windows powershell):
```console
    winget install usbipd
```

After Installation, list the USB devices and search for the FTDI device.
```console
usbipd list
```

Bind the FTDI device depending on the bus ID.
```console
usbipd bind --busid xxx-yyy
```

Attach the device to WSL
```console
usbipd attach --wsl --busid xxx-yyy
```

## All Users

Within Linux, scan USB devices and search for the FTDI device.:
```console
openFPGALoader --scan-usb
```

After, this scan, note the bus- and devicenumber, used as BUS:DEV.
```console
openFPGALoader --cable digilent_hs3 --detect --busdev-num BUS:DEV
```

On success, one should read the JTAG speed of the connected JTAG device.

