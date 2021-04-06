#!/bin/sh

echo "[deCONZ] Starting deCONZ..."

DEBUG_INFO="1"
DEBUG_APS="0"
DEBUG_ZCL="0"
DEBUG_ZDP="0"
DEBUG_OTAU="0"
DECONZ_DEVICE="/dev/ttyUSB0"
DECONZ_VNC_MODE="1"
DECONZ_VNC_DISPLAY="0"
DECONZ_VNC_PASSWORD="changeme"
DECONZ_VNC_PORT="5900"
DECONZ_UPNP="0"

DECONZ_OPTS="--auto-connect=0 \
        --dbg-info=1 \
        --dbg-aps=0 \
        --dbg-zcl=0 \
        --dbg-zdp=0 \
        --dbg-otau=0 \
        --http-port=8085 \
        --dev=/dev/ttyUSB0 \
        --ws-port=8443"

if [ "$DECONZ_VNC_MODE" != 0 ]; then
  
  if [ "$DECONZ_VNC_PORT" -lt 5900 ]; then
    echo "[deCONZ] ERROR - VNC port must be 5900 or greater!"
    exit 1
  fi

  DECONZ_VNC_DISPLAY=:$(($DECONZ_VNC_PORT - 5900))
  echo "[deCONZ] VNC port: $DECONZ_VNC_PORT"
  
  if [ ! -e /root/.vnc ]; then
    mkdir /root/.vnc
  fi
  
  # Set VNC password
  echo "$DECONZ_VNC_PASSWORD" | tigervncpasswd -f > /root/.vnc/passwd
  chmod 600 /root/.vnc/passwd

  # Cleanup previous VNC session data
  tigervncserver -kill "$DECONZ_VNC_DISPLAY"

  # Set VNC security
  tigervncserver -SecurityTypes VncAuth,TLSVnc "$DECONZ_VNC_DISPLAY"
  
  # Export VNC display variable
  export DISPLAY=$DECONZ_VNC_DISPLAY
else
  echo "[deCONZ] VNC Disabled"
  DECONZ_OPTS="$DECONZ_OPTS -platform minimal"
fi

if [ "$DECONZ_DEVICE" != 0 ]; then
  DECONZ_OPTS="$DECONZ_OPTS --dev=$DECONZ_DEVICE"
fi

if [ "$DECONZ_UPNP" != 1 ]; then
  DECONZ_OPTS="$DECONZ_OPTS --upnp=0"
fi

/usr/bin/deCONZ $DECONZ_OPTS