#!/bin/bash
NAME=${1:-living_room_map}
source /opt/ros/melodic/setup.bash
source /home/jetson/yahboomcar_auto/devel/setup.bash
mkdir -p /home/jetson/maps
cd /home/jetson/maps
rosrun map_server map_saver -f "$NAME"
