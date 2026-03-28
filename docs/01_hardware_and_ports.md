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

For the successful setup documented in this repo:

- Yahboom chassis controller path used by the driver: `/dev/ttyUSB1`
- LiDAR was launched through the YDLIDAR driver path and expected to publish `/scan`

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