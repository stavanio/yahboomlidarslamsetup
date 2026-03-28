# Yahboom ROSMASTER M1 + YDLIDAR Tmini Plus + 2D SLAM (ROS Melodic)

A practical, reproducible setup for bringing up a Yahboom ROSMASTER M1 with a YDLIDAR Tmini Plus on Jetson Nano B01, then running:

- LiDAR scan publishing
- chassis control
- odometry
- keyboard teleop
- Gmapping 2D SLAM
- RViz
- map save to .pgm and .yaml

This guide is written for someone who wants a working result, not theory.

## What this repo gives you

- known-good launch files
- helper scripts
- scan filter for bad LiDAR zero readings
- working Gmapping setup
- saved map workflow
- troubleshooting for common Yahboom + Jetson failures

## Validated on

- Robot: Yahboom ROSMASTER M1
- Compute: Jetson Nano B01
- ROS: ROS 1 Melodic
- LiDAR: YDLIDAR Tmini Plus
- SLAM: Gmapping

## Quick start

1. Install dependencies
2. Apply the Yahboom driver serial fix
3. Start base, lidar, filter, gmapping, and teleop
4. Move the robot slowly with keyboard
5. Save the map

## Main scripts

- scripts/start_base.sh
- scripts/start_lidar.sh
- scripts/start_filter.sh
- scripts/start_gmapping.sh
- scripts/start_teleop.sh
- scripts/save_map.sh

## Main docs

- docs/01_hardware_and_ports.md
- docs/02_ydlidar_tmini_plus_setup.md
- docs/03_slam_gmapping_setup.md
- docs/04_rviz_local_and_remote.md
- docs/05_troubleshooting.md
