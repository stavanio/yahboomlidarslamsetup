# Gmapping SLAM setup

This document captures the working 2D SLAM setup for Yahboom ROSMASTER M1 using Gmapping.

## Final working result

Confirmed working:

- `/odom` publishes valid odometry
- robot moves correctly from `/cmd_vel`
- keyboard teleop works
- `/scan_filtered` is published
- Gmapping runs successfully
- map save works through `map_server`

## Core architecture

Data flow:

`/scan -> scan_zero_filter.py -> /scan_filtered -> gmapping`

`/cmd_vel -> Yahboom driver -> /vel_raw -> odometry publisher -> /odom_raw -> EKF -> /odom`

## Required pieces

- working LiDAR on `/scan`
- working chassis controller path
- valid `/odom`
- scan filtering before Gmapping

## Before mapping

Three fixes must be in place or the map will be wrong even though every topic looks alive:

1. `inverted: true` in `Tmini.launch` (scan mirror)
2. `Rosmaster_Lib` 3.3.9 (IMU zeros with 2.3.3)
3. IMU filter remaps `imu/data_raw` and `imu/data` in `bringup_min.launch`, and EKF fusing only gyro yaw rate

Details and tests: `docs/07_root_causes_and_fixes.md`.

## One-command launcher

`scripts/start_mapping.sh` starts base, LiDAR, filter and Gmapping in order, logs each to `~/robot_logs/map_<timestamp>/`, and checks `/odom`, `/imu/imu_data`, `/scan`, `/scan_filtered` and `/map`. Run teleop in a second session. The five-terminal order below still works.

## Gmapping parameters

`launch/gmapping_min.launch` uses `maxUrange 6.0` and `maxRange 8.0`. The earlier 3.0 m limit threw away most returns in a normal room.

## Critical chassis fix

The Yahboom driver must use:

`self.car = Rosmaster(com="/dev/yahboom_controller")`

Without that fix, common symptoms were:

- `/voltage = 0.0`
- `/vel_raw = 0.0`
- robot does not move correctly
- odometry is useless

See:

`patches/yahboom_driver_serial_patch.md`

## Launch files

### Base bring-up

Use:

`launch/bringup_min.launch`

This starts only the required base components:

- driver node
- odometry publisher
- IMU filter
- EKF

### Gmapping

Use:

`launch/gmapping_min.launch`

Important points:

- package is `gmapping`
- executable is `slam_gmapping`
- scan is remapped to `/scan_filtered`

## Why scan filtering was needed

Raw `/scan` had many invalid `0.0` readings.

That caused Gmapping to produce maps that stayed fully unknown.

The fix was to republish the scan with invalid zero values replaced by `inf`.

That is done by:

`scripts/scan_zero_filter.py`

## Startup order

Run in separate terminals:

1. `scripts/start_base.sh`
2. `scripts/start_lidar.sh`
3. `scripts/start_filter.sh`
4. `scripts/start_gmapping.sh`
5. `scripts/start_teleop.sh`

## Teleop keys

Main keys:

- `i` forward
- `j` rotate left
- `l` rotate right
- `,` backward
- `k` stop

For first mapping, use gentle taps.

## First mapping pattern

Move slowly indoors.

Recommended pattern:

- tap `i`
- tap `k`
- tap `j` or `l`
- tap `k`
- tap `i`
- tap `k`

Do short controlled movements around visible furniture and walls.

## Save map

Use:

`scripts/save_map.sh living_room_map`

or directly:

`rosrun map_server map_saver -f living_room_map`

Expected output:

- `living_room_map.pgm`
- `living_room_map.yaml`

## Validation checks on the Jetson

Check odometry:

`rostopic echo -n3 /odom`

Check filtered scan:

`rostopic echo -n1 /scan_filtered`

Check that Gmapping is subscribed:

`rostopic info /scan_filtered`

Expected subscriber:

- `/slam_gmapping`

Check saved map files:

`ls -l /home/jetson/maps/*.pgm /home/jetson/maps/*.yaml`

## Common failure case: map is all -1

Likely causes:

- raw scan still being used instead of filtered scan
- odometry not actually working
- robot not moving enough
- robot moving too fast
- scan data too poor

## Final note

This setup was validated by successfully producing and saving an indoor living-room map.