#!/bin/bash
source /opt/ros/melodic/setup.bash
source /home/jetson/yahboomcar_auto/devel/setup.bash
roslaunch yahboomcar_bringup gmapping_min.launch
