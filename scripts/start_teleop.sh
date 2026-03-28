#!/bin/bash
source /opt/ros/melodic/setup.bash
source /home/jetson/yahboomcar_auto/devel/setup.bash
rosrun teleop_twist_keyboard teleop_twist_keyboard.py cmd_vel:=/cmd_vel
