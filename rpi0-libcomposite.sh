#!/bin/sh

set -e

G="/sys/kernel/config/usb_gadget/rpi0"
UDC_DEV=`ls /sys/class/udc`

USB_VER="0x0200" # USB 2.0
DEV_CLASS="0xEF" # Composite device
DEV_SUBCLASS="0x02"
DEV_PROTO="0x01"
VID="0x1d6b" # Linux Foundation
PID="0x0104" # Ethernet Gadget
DEVICE="0x3000" # this should be incremented any time there are breaking changes
                # to this script so that the host OS sees it as a new device and
                # re-enumerates everything rather than relying on cached values
MFG="Raspberry Pi Foundation" # Raspberry Pi
PROD="Pi Zero USB Gadget" # USB Gadget
# Retrieve Pi serial number
SERIAL="$(grep Serial /proc/cpuinfo | sed 's/Serial\s*: 0000\(\w*\)/\1/')"
#ATTR="0xC0" # Self powered
ATTR="0x80" # Bus powered
PWR="100" # 100mA
#PWR="500" # 500mA

# add colons for MAC address format
MAC="$(echo ${SERIAL} | sed 's/\(\w\w\)/:\1/g' | cut -b 2-)"
# Change the first number for each MAC address - the second digit of 2 indicates
# that these are "locally assigned (b2=1), unicast (b1=0)" addresses. This is
# so that they don't conflict with any existing vendors. Care should be taken
# not to change these two bits.
DEV_MAC1="02$(echo ${MAC} | cut -b 3-)"
HOST_MAC1="12$(echo ${MAC} | cut -b 3-)"
DEV_MAC2="22$(echo ${MAC} | cut -b 3-)"
HOST_MAC2="32$(echo ${MAC} | cut -b 3-)"

MS_VENDOR_CODE="0xcd" # Microsoft special sauce
MS_QW_SIGN="MSFT100" # more Microsoft special sauce
MS_COMPAT_ID="RNDIS" # matches Windows RNDIS drivers
MS_SUBCOMPAT_ID="5162001" # matches Windows RNDIS 6.0 driver

CFG1="RNDIS+CDC-ECM+CDC-ACM" # Windows + Linux + macOS config
#CFG2="CDC" # Linux and OSX config

# Make base gadget directory if it doesn't already exist

    if [[ ! -e $G ]]; then
        mkdir ${G}
    fi

# Set up common USB gadget specifications

    echo "${USB_VER}" > ${G}/bcdUSB
    echo "${DEV_CLASS}" > ${G}/bDeviceClass
    echo "${DEV_SUBCLASS}" > ${G}/bDeviceSubClass
    echo "${DEV_PROTO}" > ${G}/bDeviceProtocol
    echo "${VID}" > ${G}/idVendor
    echo "${PID}" > ${G}/idProduct
    echo "${DEVICE}" > ${G}/bcdDevice
    if [[ ! -e ${G}/strings/0x409 ]]; then    
	mkdir -p ${G}/strings/0x409
    fi
    echo "${MFG}" > ${G}/strings/0x409/manufacturer
    echo "${PROD}" > ${G}/strings/0x409/product
    echo "${SERIAL}" > ${G}/strings/0x409/serialnumber

# Create 1 configuration1 for all OS.
# Thanks to os_desc, Windows should use RNDIS and ignore CDC-ECM.

# Config 1

    if [[ ! -e ${G}/configs/c.1 ]]; then
	mkdir -p ${G}/configs/c.1
    fi
    echo "${ATTR}" > ${G}/configs/c.1/bmAttributes
    echo "${PWR}" > ${G}/configs/c.1/MaxPower
    if [[ ! -e ${G}/configs/c.1/strings/0x409 ]]; then
	mkdir -p ${G}/configs/c.1/strings/0x409
    fi
    echo "${CFG1}" > ${G}/configs/c.1/strings/0x409/configuration

    # On Windows 7 and later, the RNDIS 5.1 driver would be used by default,
    # but it does not work very well. The RNDIS 6.0 driver works better. In
    # order to get this driver to load automatically, we have to use a
    # Microsoft-specific extension of USB.

    echo "1" > ${G}/os_desc/use
    echo "${MS_VENDOR_CODE}" > ${G}/os_desc/b_vendor_code
    echo "${MS_QW_SIGN}" > ${G}/os_desc/qw_sign

    # Create the RNDIS function, including the Microsoft-specific bits

    if [[ ! -e ${G}/functions/rndis.usb0 ]]; then
	mkdir -p ${G}/functions/rndis.usb0
    fi
    echo "${DEV_MAC2}" > ${G}/functions/rndis.usb0/dev_addr
    echo "${HOST_MAC2}" > ${G}/functions/rndis.usb0/host_addr
    echo "${MS_COMPAT_ID}" > ${G}/functions/rndis.usb0/os_desc/interface.rndis/compatible_id
    echo "${MS_SUBCOMPAT_ID}" > ${G}/functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id
    
    # Create the CDC-ECM function

    if [[ ! -e ${G}/functions/ecm.usb1 ]]; then
	mkdir -p ${G}/functions/ecm.usb1
    fi
    echo "${DEV_MAC1}" > ${G}/functions/ecm.usb1/dev_addr
    echo "${HOST_MAC1}" > ${G}/functions/ecm.usb1/host_addr
    
# Create the CDC ACM functions directory (common for both configurations)

    if [[ ! -e ${G}/functions/acm.GS0 ]]; then
	mkdir -p ${G}/functions/acm.GS0
    fi

# Bind the RNDIS USB device and the Microsoft special sauce config

    ln -s ${G}/configs/c.1 ${G}/os_desc
    ln -s ${G}/functions/rndis.usb0 ${G}/configs/c.1
    ln -s ${G}/functions/ecm.usb1 ${G}/configs/c.1
    ln -s ${G}/functions/acm.GS0 ${G}/configs/c.1
    
# Create the gadget
    echo "${UDC_DEV}" > ${G}/UDC
    
echo "Done"
