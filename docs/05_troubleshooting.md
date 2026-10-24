# Troubleshooting

This document is symptom-based. Find the thing that is broken and check that section.

## Robot does not move from teleop

### Symptoms

- keyboard teleop starts
- pressing `i`, `j`, `l` does nothing
- `/cmd_vel` exists but robot stays still

### Checks

Check teleop is publishing:

`rostopic info /cmd_vel`

Check the driver is subscribed:

`rostopic info /cmd_vel`

Check chassis velocity output:

`rostopic echo -n3 /vel_raw`

### Likely cause

Wrong Yahboom driver serial port.

### Fix

Patch:

`self.car = Rosmaster(com="/dev/yahboom_controller")`

See:

`patches/yahboom_driver_serial_patch.md`

---

## `/voltage` is 0.0

### Symptoms

- `/voltage` publishes `0.0`
- robot does not respond correctly
- odometry does not behave

### Check

`rostopic echo -n5 /voltage`

### Likely cause

Driver opened the wrong serial device.

### Fix

Patch the Yahboom driver to use the correct controller port.

---

## `/vel_raw` stays zero

### Symptoms

- robot does not appear to move in ROS
- `/odom` does not update meaningfully

### Check

`rostopic echo -n5 /vel_raw`

### Likely causes

- wrong serial port in Yahboom driver
- base stack not running
- teleop not actually publishing commands

---

## `/scan` is missing

### Symptoms

- LiDAR launch starts but no scan topic exists

### Checks

`rostopic list | grep scan`

`rostopic type /scan`

### Likely causes

- wrong LiDAR launch file
- wrong serial path
- LiDAR not detected
- driver build problem

### Fix

Use the model-correct launch profile for Tmini Plus and verify device detection.

---

## `/scan` exists but Gmapping map is all -1

### Symptoms

- Gmapping launches
- `/map` exists
- saved map is entirely unknown

### Likely causes

- raw `/scan` is being used instead of filtered scan
- scan contains many `0.0` values
- odometry is not actually working
- robot has not moved enough
- robot moved too fast

### Checks

Check filtered scan:

`rostopic echo -n1 /scan_filtered`

Check Gmapping subscriber:

`rostopic info /scan_filtered`

Expected subscriber:

- `/slam_gmapping`

Check odometry:

`rostopic echo -n3 /odom`

### Fix

- use `scripts/scan_zero_filter.py`
- ensure `launch/gmapping_min.launch` remaps to `/scan_filtered`
- move slowly with short teleop taps

---

## Gmapping launch fails

### Symptoms

- launch error for package or node type
- Gmapping does not start

### Likely cause

Wrong package name.

### Fix

Use:

- package: `gmapping`
- executable: `slam_gmapping`

---

## Teleop works but odom looks wrong

### Symptoms

- robot physically moves
- `/odom` stays zero or nonsense
- map quality is poor

### Checks

`rostopic echo -n3 /odom_raw`

`rostopic echo -n3 /odom`

`rosrun tf tf_echo odom base_footprint`

### Likely causes

- base stack incomplete
- wrong remaps
- EKF not running
- bad chassis velocity feedback

### Fix

Use `launch/bringup_min.launch` and confirm all nodes are alive.

---

## RViz shows nothing

### Checks

- correct Fixed Frame
- correct topic selected
- stack is running
- for remote RViz: ROS networking variables are correct

See:

`docs/04_rviz_local_and_remote.md`

---

## `Unable to communicate with master!`

### Symptoms

- `rostopic` commands fail
- `rosrun` says it cannot reach master

### Likely cause

ROS master is not running in the current session.

### Fix

Restart the stack cleanly.

---

## You changed USB wiring and things broke

### Symptoms

- robot worked before
- after moving dongles or swapping USB ports, it stopped working

### Likely cause

Serial-device enumeration changed.

### Fix

Re-check:

`ls -l /dev/ttyUSB* /dev/ttyACM* /dev/ttyTHS* 2>/dev/null`

Then verify the Yahboom driver port and LiDAR port again.

---

## Safe restart order

If everything is messy, stop all running nodes and restart in this order:

1. `scripts/start_base.sh`
2. `scripts/start_lidar.sh`
3. `scripts/start_filter.sh`
4. `scripts/start_gmapping.sh`
5. `scripts/start_teleop.sh`

---

## Final sanity checklist

Before mapping, confirm all of these:

- `/scan` exists
- `/scan_filtered` exists
- `/cmd_vel` works
- `/vel_raw` changes when robot moves
- `/odom` updates
- `/slam_gmapping` is running
- map save creates `.pgm` and `.yaml`
---

## Map shows walls repeated at different angles

### Likely cause

LiDAR scan mirrored relative to the robot.

### Check

Front-left object test in `docs/07_root_causes_and_fixes.md`, section 1. A front-left object must read a positive angle.

### Fix

`inverted: true` in `Tmini.launch`, then rebuild the map.

---

## IMU filter says `Still waiting for data on topic /imu/data_raw`

### Checks

`rostopic hz /imu/imu_raw`

`rostopic echo -n1 /imu/imu_raw/linear_acceleration`

### Likely causes

- IMU filter remaps use `/sub_imu` and `/pub_imu`, which the node ignores. Use `imu/data_raw` and `imu/data`.
- `/imu/imu_raw` publishes but every value is 0.0: `Rosmaster_Lib` 2.3.3 is loaded. Install 3.3.9.

---

## `Unable to contact my own server at [http://OLD_IP:...]`

### Cause

`ROS_MASTER_URI` and `ROS_IP` in `~/.bashrc` still point at the address from a previous network.

### Fix

Update both lines in `~/.bashrc`, then `source ~/.bashrc` in every open session. Sessions opened before the edit keep the old values.

---

## Navigation goal aborts with `robot appears to be oscillating`

### Cause

`oscillation_timeout` shorter than a slow in-place turn. At 0.3 rad/s a 90 deg turn takes about 5 s and moves 0 m.

### Fix

`oscillation_timeout 20.0` in `move_base_min.launch`.

---

## Robot sits facing the wrong way until the goal times out

### Cause

With strafing off, DWA cannot see a benefit from turning when `sim_time` and `forward_point_distance` are small.

### Fix

`sim_time 2.5`, `forward_point_distance 0.3` in `dwa_local_planner.yaml`.

---

## Robot reports goal reached but stops short

### Cause

`xy_goal_tolerance` with `latch_xy_goal_tolerance: true`. The robot stops at the first point inside the circle, which is always on the approach side.

### Fix

`xy_goal_tolerance 0.04`. Going much lower makes the robot creep near the goal.

---

## Robot crabs sideways and skids on hard floors

### Cause

Mecanum strafing slips on glossy floors.

### Fix

`holonomic_robot: false`, `max_vel_y 0`, `min_vel_y 0`, `vy_samples 1`. Keep `min_vel_x -0.05` so the robot can back onto a goal instead of spinning 180 deg at the end.
