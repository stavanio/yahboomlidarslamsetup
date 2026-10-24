from __future__ import print_function
import rospy, math, sys
from nav_msgs.msg import Odometry
rospy.init_node("odom_scale")
start = []
def cb(m):
    p = m.pose.pose.position
    if not start:
        start.extend([p.x, p.y])
    d = math.hypot(p.x - start[0], p.y - start[1])
    sys.stdout.write("wheel odom distance: %.3f m   \r" % d)
    sys.stdout.flush()
rospy.Subscriber("/odom_raw", Odometry, cb)
rospy.spin()
