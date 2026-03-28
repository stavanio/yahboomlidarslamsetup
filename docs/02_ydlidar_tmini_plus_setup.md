# YDLIDAR Tmini Plus setup

This document captures the working YDLIDAR Tmini Plus bring-up on Yahboom ROSMASTER M1 under ROS 1 Melodic.

## Final working result

Confirmed working:

- `/scan` exists
- `rostopic type /scan` returns `sensor_msgs/LaserScan`
- scan rate is about `6 Hz`
- valid `ranges` and `intensities` are published

## Correct launch file

Use the model-specific launch file:

`Tmini.launch`

Do not use the generic default LiDAR launch if the Tmini Plus is not behaving correctly.

## Important settings

The working launch used settings consistent with:

- baudrate `230400`
- `lidar_type = 1`
- `sample_rate = 4`
- `isSingleChannel = false`

## Device mapping

In the validated setup, controller and LiDAR appeared as separate serial devices.

Important lesson:

- do not assume the first `/dev/ttyUSB*` device is the LiDAR
- verify what the LiDAR really is before patching launch files

## Stable alias recommendation

Use a persistent udev alias such as:

`/dev/ydlidar`

That keeps launch files stable across reboots.

## Basic verification on the Jetson

Check scan topic:

`rostopic list | grep scan`

Check scan type:

`rostopic type /scan`

Check scan rate:

`rostopic hz /scan`

Check one scan message:

`rostopic echo -n1 /scan`

## Common symptoms

### `/scan` missing
Possible causes:

- wrong launch file
- wrong serial path
- LiDAR not detected
- driver not built correctly

### Checksum spam or bad scan behavior
Possible causes:

- wrong launch profile
- wrong baudrate
- wrong LiDAR model configuration

### Topic exists but data is poor
Possible causes:

- unstable serial mapping
- wrong device path
- scan contains many invalid readings

## Final note

This LiDAR setup is the foundation for the SLAM setup in:

`docs/03_slam_gmapping_setup.md`