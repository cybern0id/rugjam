# rugjam
(R)aspberry Pi (U)SB (G)adget (J)TAG for (A) (M)ega65

My initial objective was to find an alternative to the official TE0790-03(L) XMOD FTDI JTAG adapter available from Trenz. I wanted to use a Raspberry Pi Zero as a programmer and interface for the Xilinx Artix-7 FPGA on the [Mega65 8-bit computer](https://github.com/MEGA65/) but soon realised that the Pi could be turned into a USB attached gadget device, rather than just a stand alone general purpose computer.

This collection of scripts and config files are presented here in the hope they can assist in easily setting up a Raspberry Pi as a multi-function USB gadget device that can be connected to your desktop or notebook computer.

Once configured, the USB attached Raspberry Pi gadget will act as:

- a USB to serial UART bridge

  The RPi gadget will present itself to your Windows, Linux or MacOS computer as a regular USB serial device (UART/ACM Modem) which the mega65-tools, like m65
or mega65_ftp, can use to interact with the Mega65. Serial communication sent from the host via the USB RPi gadget then on to the Mega65 is facilitated by using [socat](http://www.dest-unreach.org/socat/) running on the gadget to forward all data.

- a Xilinx JTAG programmer

  FPGA programming can be done using Vivado once connected to the Xilinx Virtual Cable Server running on the gadget (which uses [xvcpi](https://github.com/derekmulcahy/xvcpi))
  
  OR
  
  FPGA programming can be done directly using tools local to the device - this requires logging in via SSH to the Raspberry Pi and using [xc3sprog](https://github.com/matrix-io/xc3sprog), [openocd](https://github.com/openocd-org/openocd), [openFPGAloader](https://github.com/trabucayre/openFPGALoader) etc. The RPi gadget presents a USB to ethernet bridge to facilitate this, using your desktop or laptop computer's internet connected network hardware as a route to the internet (internet sharing must be turned on).

These scripts are designed to run on [Alpine Linux armhf edition for Raspberry Pi](https://www.alpinelinux.org/downloads/). Alpine was chosen as it is very lightweight, easy to configure and doesn't use systemd (and so is not overly complicated IMHO).

Still to do:
- Add photos, wiring diagrams.
- Document GPIO pins used.
- Add a programmer for Mega65's Max-10 FPGA (current idea will require deboostrap or similar to deploy and run a chroot glibc based armhf Debian distro as Alpine's musl libc won't run the app I have in mind).
- fine tuning and optimisation of scripts.
- attempt Pi usbboot to remove requirement for uSD card in the Pi (unfortunately, already tested usbboot and it doesn't work for Pi Zero on MacOS Ventura - other OS or Pi versions may do so - initial testing with Pi Zero 2 (02) shows promise on MacOS).
- make changes to m65 mega65 tool so that it recognises Pi gadget's Xilinx Virtual Cable Server.

Requirements:
- Raspberry Pi Zero, Zero W, Zero 2, Zero 2W (possibly Pi 3 but untested to date).
- uSD card >8GB.
- Soldered GPIO pin header on the Pi.
- Dupont style female to female jumper wires (at least 8 of them).
- A brave heart and strong stomach.
- Patience.
- A USB to USB micro cable to connect between desktop/notebook computer and the Pi.

Directions:
- Download and verify alpine linux armhf for Raspberry Pi.
- Prepare uSD card.
- Run scripts to deploy Alpine Linux, config files and deploy scripts.

    Use OS specific shell script in this repo to faciliate these first steps.
    
    Format uSD with two FAT32 partitions. Ensure second partition is >7GB. First partition can be >512MB.
    
    Decompress Alpine Linux download to first partition of uSD card.
    
    Download headless overlay for Alpine Linux, decompress, make relavent changes, recompress.
    
    Copy this adjusted headless overlay file to first partition of uSD card.
    
    Copy interfaces, cmdline.txt, config.txt, rpi-libcomposite.sh, set-win-dns.sh and unattended.sh files from this repo to first partition of uSD card.
    
    Create two raw disk image files of approximately 3GB in size each, on second partition of uSD card, one named 'persist.img' and the other named 'userfiles.img'.
    ``fallocate`` on Linux or ``mkfile`` on Macos can achieve this. ``fsutil file createnew`` for Windows should do the same.
      
- Correctly connect jumper wires between Pi and Mega65. Check wiring thrice.
- Set up internet connection sharing for your primary network device on your desktop/notebook computer.
- Insert uSD to Pi; Boot Pi using USB cable connected to USB "data" micro port on Pi.
- (May need to re-check and disable/re-enable internet connection sharing at this point for Windows).
- Wait a while.
- Check Pi gadget serial UART/ACM modem device is detected by your desktop/notebook.
- Try connecting to Pi via SSH or sending m65 command.
