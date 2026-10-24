import rospy, actionlib, math
from move_base_msgs.msg import MoveBaseAction, MoveBaseGoal
rospy.init_node("nav_test")
client = actionlib.SimpleActionClient("move_base", MoveBaseAction)
client.wait_for_server()
def go(x, y, yaw_deg, timeout=40):
    g = MoveBaseGoal()
    g.target_pose.header.frame_id = "map"
    g.target_pose.header.stamp = rospy.Time.now()
    g.target_pose.pose.position.x = x
    g.target_pose.pose.position.y = y
    yaw = math.radians(yaw_deg)
    g.target_pose.pose.orientation.z = math.sin(yaw / 2)
    g.target_pose.pose.orientation.w = math.cos(yaw / 2)
    print("goal (%.2f, %.2f) yaw %d" % (x, y, yaw_deg))
    client.send_goal(g)
    if not client.wait_for_result(rospy.Duration(timeout)):
        client.cancel_goal()
        print("  TIMEOUT")
        return False
    ok = client.get_state() == 3
    print("  reached" if ok else "  failed, state %d" % client.get_state())
    return ok
try:
    go(0.5, 0.0, 0) and go(0.5, 0.0, 90) and go(0.0, 0.0, 0)
except KeyboardInterrupt:
    client.cancel_goal()
