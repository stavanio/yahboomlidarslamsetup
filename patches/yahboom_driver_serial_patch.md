# Yahboom driver serial-port patch

## Why this patch is needed

On this setup, the Yahboom chassis controller did not work correctly when the Python driver used the default serial port.

Symptoms of the wrong port included:

- /voltage stayed 0.0
- /vel_raw stayed zero
- robot would not move correctly from ROS
- /odom did not become useful

The fix was to force the Yahboom driver to use:

self.car = Rosmaster(com="/dev/ttyUSB1")

## File to patch

/home/jetson/yahboomcar_auto/src/yahboomcar_bringup/scripts/Mcnamu_driver.py

## What to change

Find:

self.car = Rosmaster()

Change to:

self.car = Rosmaster(com="/dev/ttyUSB1")

## How to verify the patch

On the Jetson run:

grep -n "self.car = Rosmaster" /home/jetson/yahboomcar_auto/src/yahboomcar_bringup/scripts/Mcnamu_driver.py

Expected result:

self.car = Rosmaster(com="/dev/ttyUSB1")

## Important note

This port mapping was correct for the validated working setup in this repo.

If your hardware enumerates differently, verify which /dev/ttyUSB* device actually corresponds to the Yahboom chassis controller before changing this line blindly.
