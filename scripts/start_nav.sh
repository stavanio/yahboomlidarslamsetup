#!/bin/bash
source /opt/ros/melodic/setup.bash
source /home/jetson/yahboomcar_auto/devel/setup.bash
export ROS_MASTER_URI=http://192.168.88.22:11311
export ROS_IP=192.168.88.22

LOG=~/robot_logs/nav_$(date +%Y%m%d_%H%M%S)
mkdir -p $LOG
trap 'kill $(jobs -p) 2>/dev/null; wait; echo stopped' INT TERM

roslaunch yahboomcar_bringup bringup_min.launch > $LOG/base.log 2>&1 &
until rostopic list > /dev/null 2>&1; do sleep 1; done
sleep 3
roslaunch ydlidar_ros_driver Tmini.launch > $LOG/lidar.log 2>&1 &
sleep 5
python3 /home/jetson/yahboom_scan_tools/scan_zero_filter.py > $LOG/filter.log 2>&1 &
sleep 2
roslaunch /home/jetson/robot_nav/localization_min.launch > $LOG/amcl.log 2>&1 &
sleep 5
rostopic pub -1 /initialpose geometry_msgs/PoseWithCovarianceStamped '{header: {frame_id: map}, pose: {pose: {position: {x: 0.0, y: 0.0}, orientation: {w: 1.0}}, covariance: [0.05,0,0,0,0,0, 0,0.05,0,0,0,0, 0,0,0,0,0,0, 0,0,0,0,0,0, 0,0,0,0,0,0, 0,0,0,0,0,0.05]}}' > /dev/null
roslaunch /home/jetson/robot_nav/move_base_min.launch > $LOG/move_base.log 2>&1 &
sleep 8

for t in /odom /imu/imu_data /scan_filtered /map /amcl_pose; do
  if timeout 8 rostopic echo -n1 $t > /dev/null 2>&1; then echo "OK      $t"; else echo "MISSING $t"; fi
done
rosnode list | grep -q move_base && echo "OK      move_base" || echo "MISSING move_base"
echo "Logs: $LOG"
echo "Ready. Ctrl+C here stops everything."
wait
