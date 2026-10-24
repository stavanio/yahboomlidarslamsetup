# Autonomous navigation: AMCL + move_base

Localization on a saved Gmapping map with AMCL, path planning with `global_planner`, and local control with DWA.

## File locations on the Jetson

The launchers expect files here:

| Repo file | Jetson path |
|---|---|
| `launch/bringup_min.launch` | `~/yahboomcar_auto/src/yahboomcar_bringup/launch/` |
| `launch/gmapping_min.launch` | `~/yahboomcar_auto/src/yahboomcar_bringup/launch/` |
| `params/robot_localization.yaml` | `~/yahboomcar_auto/src/yahboomcar_bringup/param/` |
| `launch/Tmini.launch` | `~/yahboomcar_auto/src/ydlidar_ros_driver/launch/` |
| `launch/localization_min.launch` | `~/robot_nav/` |
| `launch/move_base_min.launch` | `~/robot_nav/` |
| `params/*_costmap.yaml`, `costmap_common.yaml`, `dwa_local_planner.yaml` | `~/robot_nav/params/` |
| `maps/my_map.*` | `~/robot_nav/` |
| `scripts/*` | `~/robot_scripts/` |
| `scripts/scan_zero_filter.py` | `~/yahboom_scan_tools/` |
| `udev/*.rules` | `/etc/udev/rules.d/` |

`start_mapping.sh` and `start_nav.sh` hardcode `ROS_MASTER_URI` and `ROS_IP` as `192.168.88.22`. Change both if your Jetson has a different address.

## Build the map

1. Mark the start spot on the floor (tape and an arrow). It becomes map origin (0, 0, 0).
2. Session 1: `bash ~/robot_scripts/start_mapping.sh`. Wait for five `OK` lines.
3. Session 2: `bash ~/robot_scripts/start_teleop.sh`. Press `z` until speeds are about 0.1 m/s and 0.3 rad/s.
4. Drive a loop: perimeter first, then the middle, slow turns with a pause after each. Stay within 2 m of walls or furniture. End back on the mark.
5. Save while Gmapping is running: `rosrun map_server map_saver -f ~/robot_nav/my_map`

A good map has straight, single-copy walls and a closed outline. Walls repeated at an angle mean the scan orientation is wrong (`docs/07_root_causes_and_fixes.md`, section 1).

## Navigate

1. Robot on the mark, facing the same direction as when mapping started.
2. Session 1: `bash ~/robot_scripts/start_nav.sh`. It starts base, LiDAR, filter, AMCL, publishes `/initialpose` at the origin, starts move_base, then checks topics. Wait for six `OK` lines.
3. Session 2: `python ~/robot_scripts/nav_test.py`

`nav_test.py` sends three goals in the `map` frame: (0.5, 0, 0 deg), (0.5, 0, 90 deg), (0, 0, 0 deg). Expected output is `reached` three times.

Between repeated runs do not restart the stack. Put the robot back on the mark and re-publish the start pose:

```bash
rostopic pub -1 /initialpose geometry_msgs/PoseWithCovarianceStamped '{header: {frame_id: map}, pose: {pose: {position: {x: 0.0, y: 0.0}, orientation: {w: 1.0}}, covariance: [0.05,0,0,0,0,0, 0,0.05,0,0,0,0, 0,0,0,0,0,0, 0,0,0,0,0,0, 0,0,0,0,0,0, 0,0,0,0,0,0.05]}}'
```

Restart `start_nav.sh` only after editing a config file. move_base and AMCL read parameters at startup.

Emergency stop from any session: `bash ~/robot_scripts/emergency_stop.sh`

Logs for every run are in `~/robot_logs/nav_<timestamp>/`.

## Key parameters

DWA (`params/dwa_local_planner.yaml`):

- max 0.10 m/s forward, 0.05 m/s reverse, 0.3 rad/s turn
- strafing off (`holonomic_robot: false`, `max_vel_y 0`)
- `acc_lim_x 0.25`, `acc_lim_theta 0.8`
- `sim_time 2.5`, `forward_point_distance 0.3`
- `xy_goal_tolerance 0.04`, `yaw_goal_tolerance 0.15`

AMCL (`launch/localization_min.launch`):

- 300 to 1500 particles, 120 beams, `laser_sigma_hit 0.1`
- update every 0.05 m or 0.05 rad
- `odom_model_type omni`, `transform_tolerance 0.5`
- reads `/scan_filtered`

move_base (`launch/move_base_min.launch`):

- no velocity smoother, publishes `/cmd_vel` directly
- `oscillation_timeout 20.0`, recovery behaviors off

## Checks

Where AMCL thinks the robot is:

```bash
rostopic echo -n1 /amcl_pose | grep -A3 "position:"
```

Map frame: forward from the start is +x, left is +y.

Is a parameter actually loaded:

```bash
rosparam get /move_base/DWAPlannerROS/min_vel_x
```

CPU headroom (AMCL at 120 beams stayed under 5%, system about 82% idle):

```bash
top -b -n1 | head -15
```

## Odometry scale check

`scripts/odom_scale.py` prints distance from `/odom_raw` since it started. Lay a tape measure parallel to the robot, drive straight with teleop, stop anywhere past 1.5 m, and compare. Scale is tape distance divided by odometry distance. Short runs exaggerate reading error; use 2 m or more.

## Measured results (living room, glossy hardwood)

| Stage | Return-to-start offset |
|---|---|
| Original config | goals timed out or drove the wrong way |
| Smoother removed, tolerances fixed, strafe on | about 7 in sideways (20 cm goal tolerance) |
| Goal tolerance 0.08 | 5 to 6 in short on the approach side |
| AMCL 120 beams, sigma 0.1 | about 1 in, heading about 20 deg off |
| Gentler acceleration, goal tolerance 0.04 | negligible forward error, about 1 in sideways, heading about 10 deg |

A room with walls within a few meters on every side should localize better than an open living room where most returns are furniture legs.
