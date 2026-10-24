# Hardware and port layout

This document explains the expected hardware layout for the validated Yahboom ROSMASTER M1 + YDLIDAR Tmini Plus setup.

## Robot

- Yahboom ROSMASTER M1
- Jetson Nano B01
- ROS 1 Melodic
- YDLIDAR Tmini Plus

## Expected USB / serial behavior

In the validated working setup, the system exposed serial devices like:

- `/dev/ttyUSB0`
- `/dev/ttyUSB1`

The important point is that the Yahboom chassis controller and LiDAR did not end up on the same serial device.

## Critical working mapping

Use the udev aliases in `udev/`, not raw `ttyUSB` numbers:

- Yahboom expansion board (CH340, USB id `7523`): `/dev/yahboom_controller`
- YDLIDAR Tmini Plus (CP2102, USB id `10c4:ea60`): `/dev/ydlidar`

The March version of this setup used `/dev/ttyUSB1` for the board. That only worked while enumeration order held.

## Python library

The driver needs `Rosmaster_Lib` 3.3.9 for board firmware 3.6. An older 2.3.3 egg in `/usr/local/lib/python3.6/dist-packages/` will load first if present and return all-zero IMU data. Check:

`python3 -c "import Rosmaster_Lib; print(Rosmaster_Lib.__file__)"`

Install steps are in `docs/07_root_causes_and_fixes.md`, section 2.

## Why this matters

If the wrong serial device is used for the Yahboom chassis driver, symptoms may include:

- `/voltage` stays `0.0`
- `/vel_raw` stays zero
- robot does not move from ROS
- odometry is dead

If LiDAR is misconfigured, symptoms may include:

- `/scan` missing
- checksum errors
- bad scan values
- Gmapping map staying all `-1`

## Useful checks on the Jetson

Check available serial devices:

`ls -l /dev/ttyUSB* /dev/ttyACM* /dev/ttyTHS* 2>/dev/null`

Check the Yahboom driver patch:

`grep -n "self.car = Rosmaster" /home/jetson/yahboomcar_auto/src/yahboomcar_bringup/scripts/Mcnamu_driver.py`

Check LiDAR topic:

`rostopic type /scan`

`rostopic hz /scan`

## Important note

USB enumeration can change across systems.

Do not blindly assume your robot will always match the same `/dev/ttyUSB*` numbering unless you verify it.