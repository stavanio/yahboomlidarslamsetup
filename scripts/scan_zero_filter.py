#!/usr/bin/env python3
import math
import rospy
from sensor_msgs.msg import LaserScan

pub = None

def cb(msg):
    out = LaserScan()
    out.header = msg.header
    out.angle_min = msg.angle_min
    out.angle_max = msg.angle_max
    out.angle_increment = msg.angle_increment
    out.time_increment = msg.time_increment
    out.scan_time = msg.scan_time
    out.range_min = msg.range_min
    out.range_max = msg.range_max
    out.intensities = list(msg.intensities)

    fixed = []
    replacement = float('inf')

    for r in msg.ranges:
        if r == 0.0 or r < msg.range_min:
            fixed.append(replacement)
        else:
            fixed.append(r)

    out.ranges = fixed
    pub.publish(out)

if __name__ == "__main__":
    rospy.init_node("scan_zero_filter")
    pub = rospy.Publisher("/scan_filtered", LaserScan, queue_size=10)
    rospy.Subscriber("/scan", LaserScan, cb, queue_size=10)
    rospy.spin()
