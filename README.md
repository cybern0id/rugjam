# rugjam
(R)aspberry Pi (U)SB (G)adget (J)TAG for (A) (M)ega65

My initial objective was to use a Raspberry Pi Zero as a programmer and interface for the Xilinx Artix-7 FPGA on the [Mega65 8-bit computer](https://github.com/MEGA65/).
I soon realised I could turn a Raspberry Pi into a USB attached gadget, rather than use it as stand alone general purpose computer.

This collection of scripts and config files are presented here in the hope they can assist in easily setting up a Raspberry Pi as a multi-function USB gadget device that can be connected to your desktop or notebook computer.

Once configured, the USB attached Raspberry Pi gadget will act as:

- a USB to serial UART bridge

  The RPi gadget will present itself to your Windows, Linux or MacOS computer as a regular USB serial device (UART/ACM Modem) which the mega65-tools, like m65
or mega65_ftp, can use to interact with the Mega65. Serial communication sent from the host via the USB RPi gadget then on to the Mega65 is facilitated by using [socat](http://www.dest-unreach.org/socat/) running on the gadget to forward all data.

- a Xilinx JTAG programmer

  FPGA programming can be done using Vivado once connected to the Xilinx Virtual Cable Server running on the gadget (which uses [xvcpi](https://github.com/derekmulcahy/xvcpi))
  
  OR
  
  FPGA programming can be done directly using tools local to the device - this requires logging in via SSH to the Raspberry Pi and using [xc3sprog](https://github.com/matrix-io/xc3sprog), [openocd](https://github.com/openocd-org/openocd),
[openFPGAloader](https://github.com/trabucayre/openFPGALoader) etc. The RPi gadget presents a USB to ethernet bridge to facilitate this, using your desktop or laptop computer's internet connected network hardware as a
route to the internet (internet sharing must be turned on).

These scripts are designed to run on Alpine Linux armhf edition for Raspberry Pi. Alpine was chosen as it is very lightweight, easy to configure and doesn't use systemd (and so is not overly complicated IMHO).

Still to do:
- Add photos, wiring diagrams.
- Document GPIO pins used
- Add a programmer for Mega65's Max-10 FPGA
- fine tuning and optimisation of scripts
- attempt Pi usbboot to remove requirement for uSD card in the Pi (unfortunately, already tested usbboot and it doesn't work for Pi Zero on MacOS Ventura - other OS or Pi versions may do so - initial testing with Pi Zero 2 (02) shows promise on MacOS)
- make changes to m65 mega65 tool so that it recognises Pi gadget's Xilinx Virtual Cable Server.
