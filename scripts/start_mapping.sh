#!/bin/bash
source /opt/ros/melodic/setup.bash
source /home/jetson/yahboomcar_auto/devel/setup.bash
export ROS_MASTER_URI=http://192.168.88.22:11311
export ROS_IP=192.168.88.22

LOG=~/robot_logs/map_$(date +%Y%m%d_%H%M%S)
mkdir -p $LOG
trap 'kill $(jobs -p) 2>/dev/null; wait; echo stopped' INT TERM

roslaunch yahboomcar_bringup bringup_min.launch > $LOG/base.log 2>&1 &
until rostopic list > /dev/null 2>&1; do sleep 1; done
sleep 3
roslaunch ydlidar_ros_driver Tmini.launch > $LOG/lidar.log 2>&1 &
sleep 5
python3 /home/jetson/yahboom_scan_tools/scan_zero_filter.py > $LOG/filter.log 2>&1 &
sleep 2
roslaunch yahboomcar_bringup gmapping_min.launch > $LOG/gmapping.log 2>&1 &
sleep 6

for t in /odom /imu/imu_data /scan /scan_filtered /map; do
  if timeout 8 rostopic echo -n1 $t > /dev/null 2>&1; then echo "OK      $t"; else echo "MISSING $t"; fi
done
echo "Logs: $LOG"
echo "Ready. Ctrl+C here stops everything."
wait
