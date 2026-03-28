# RViz: local and remote usage

This document explains how to use RViz with the Yahboom ROSMASTER M1 setup.

## Option 1: RViz on the Jetson

If the Jetson has a desktop session and enough resources, install RViz:

`sudo apt update`

`sudo apt install -y ros-melodic-rviz`

Run:

`rviz`

Notes:

- this can be heavy on a Jetson Nano
- it may be slower than using a laptop
- it is acceptable for basic visualization

## Option 2: RViz on a remote Ubuntu laptop

This is often the easier and cleaner option.

### On the Jetson

Start the robot stack normally.

Find the Jetson IP:

`hostname -I`

Example:

`192.168.185.27`

### On the Ubuntu laptop

Set ROS networking:

`export ROS_MASTER_URI=http://JETSON_IP:11311`

`export ROS_IP=YOUR_LAPTOP_IP`

Replace:

- `JETSON_IP` with the Jetson address
- `YOUR_LAPTOP_IP` with your laptop address on the same network

Then run:

`rviz`

## What to display in RViz

### For LiDAR only

- Fixed Frame: `laser_frame` or `base_footprint`
- Add display: `LaserScan`
- Topic: `/scan`

### For filtered scan

- Fixed Frame: `base_footprint`
- Add display: `LaserScan`
- Topic: `/scan_filtered`

### For SLAM

- Fixed Frame: `map`
- Add display: `Map`
- Topic: `/map`
- Add display: `LaserScan`
- Topic: `/scan_filtered`
- Add display: `TF`

## What success looks like

During SLAM:

- the map updates as the robot moves
- walls and furniture boundaries become visible
- free space appears around traversed areas
- unexplored space remains unknown

## Common RViz problems

### RViz opens but shows nothing

Check:

- correct Fixed Frame
- correct topic selected
- robot stack is actually running
- ROS networking variables are correct

### Remote RViz cannot see Jetson topics

Check:

- both machines are on the same network
- `ROS_MASTER_URI` is set correctly
- `ROS_IP` is set correctly
- Jetson ROS core is running

### Jetson RViz is slow

This is common on Jetson Nano.

Use a remote Ubuntu laptop if possible.

## Recommendation

For regular SLAM work:

- use Jetson for robot runtime
- use Ubuntu laptop for RViz when available

For first proof of mapping:

- RViz is helpful but not mandatory
- map save to `.pgm` and `.yaml` is enough to prove success