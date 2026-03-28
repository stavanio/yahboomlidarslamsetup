#!/bin/bash
set -e

sudo apt update
sudo apt install -y \
  ros-melodic-robot-localization \
  ros-melodic-imu-filter-madgwick \
  ros-melodic-slam-gmapping \
  ros-melodic-map-server \
  ros-melodic-rviz \
  ros-melodic-teleop-twist-keyboard
