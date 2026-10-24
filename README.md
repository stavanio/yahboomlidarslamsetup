# Yahboom ROSMASTER M1 + YDLIDAR Tmini Plus: SLAM and Autonomous Navigation (ROS Melodic)

A reproducible setup for a Yahboom ROSMASTER M1 (Mecanum, Jetson Nano B01, ROS 1 Melodic) with a YDLIDAR Tmini Plus. It covers:

- LiDAR bring-up and the correct scan orientation
- chassis driver, wheel odometry, IMU and EKF fusion
- Gmapping 2D SLAM and map saving
- AMCL localization on a saved map
- move_base autonomous navigation with DWA
- one-command launchers for mapping and navigation
- tests for scan orientation, odometry scale and goal accuracy

## Validated on

- Robot: Yahboom ROSMASTER M1, driver car type X3 (`set_car_type(10)`), Mecanum wheels
- Compute: Jetson Nano B01 4GB, Ubuntu 18.04
- ROS: Melodic
- LiDAR: YDLIDAR Tmini Plus (CP2102, 230400 baud)
- Expansion board firmware: 3.6
- `Rosmaster_Lib`: 3.3.9 (2.3.3 does not work with firmware 3.6, see below)

## Status

- Mapping: clean single-copy walls after the scan orientation fix
- Navigation: `scripts/nav_test.py` reaches all three goals (forward 0.5 m, turn 90 deg, return to start)
- Return-to-start accuracy in a living room on hardwood: about 1 inch, heading within about 10 deg
- Wheel odometry: 2.017 m reported over 2.000 m measured (0.8%)

## Read this first

Four problems made the robot skid, map badly and drive the wrong way. All four are fixed here and explained in `docs/07_root_causes_and_fixes.md`:

1. LiDAR scan was mirrored left to right (`inverted` in `Tmini.launch`)
2. IMU published all zeros because the installed `Rosmaster_Lib` 2.3.3 cannot decode firmware 3.6 IMU packets
3. IMU filter topic remaps did not match, so the EKF never received IMU data
4. Navigation config fought the robot: velocity smoother dropped strafe commands, goal heading tolerance was a full circle, AMCL was too heavy for the Nano

## Quick start

1. Install dependencies: `scripts/install_dependencies.sh`
2. Install `Rosmaster_Lib` 3.3.9 (`docs/01_hardware_and_ports.md`)
3. Install the udev rules in `udev/`
4. Copy the launch and param files to the paths listed in `docs/06_navigation.md`
5. Build a map: `scripts/start_mapping.sh` plus `scripts/start_teleop.sh`
6. Navigate: `scripts/start_nav.sh`, then `python scripts/nav_test.py`

## Layout

```
launch/   bringup_min, gmapping_min, Tmini, localization_min, move_base_min
params/   dwa_local_planner, costmap_common, global_costmap, local_costmap, robot_localization
scripts/  start_mapping.sh, start_nav.sh, start_*.sh, nav_test.py, odom_scale.py, emergency_stop.sh, scan_zero_filter.py
udev/     stable /dev/yahboom_controller and /dev/ydlidar aliases
maps/     my_map (current), living_room_map (March, built before the scan fix)
docs/     setup, SLAM, RViz, troubleshooting, navigation, root causes
patches/  driver serial port
```

## Docs

- `docs/01_hardware_and_ports.md`
- `docs/02_ydlidar_tmini_plus_setup.md`
- `docs/03_slam_gmapping_setup.md`
- `docs/04_rviz_local_and_remote.md`
- `docs/05_troubleshooting.md`
- `docs/06_navigation.md`
- `docs/07_root_causes_and_fixes.md`
