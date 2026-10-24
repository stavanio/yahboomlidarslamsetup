# Root causes and fixes

The robot skidded, drove the wrong way on map goals, and produced maps with walls repeated at several angles. Each cause below was confirmed with a test before it was fixed. Order matters: fix them top to bottom.

## 1. LiDAR scan mirrored left to right

**Symptom.** Maps show the same walls laid down again at 20 to 45 deg angles. Navigation turns the wrong way. An in-place rotation test of odometry looks fine, because odometry was never the problem.

**Test.** Put the robot in open floor. Place a tall object (taller than about 30 cm; a shoe is below the scan plane) about 0.5 m away at the robot's front left. Print the nearest return in the robot frame (left is positive):

```python
from __future__ import print_function
import rospy, math, sys
from sensor_msgs.msg import LaserScan
YAW = math.pi  # base_footprint -> laser_frame yaw from Tmini.launch
rospy.init_node("lidar_dir")
def cb(s):
    best = None
    for i, r in enumerate(s.ranges):
        if 0.15 < r < 1.0 and (best is None or r < best[0]):
            best = (r, s.angle_min + i * s.angle_increment)
    if best:
        a = math.degrees(math.atan2(math.sin(best[1] + YAW), math.cos(best[1] + YAW)))
        sys.stdout.write("nearest %.2f m at %4.0f deg\r" % (best[0], a))
        sys.stdout.flush()
rospy.Subscriber("/scan", LaserScan, cb)
rospy.spin()
```

Run it with `python` (Python 2). The Melodic `tf` module does not import under Python 3.

Before the fix it read **-24 deg** for an object at the front left. After the fix it read **+24 deg**.

**Fix.** In `Tmini.launch`, `inverted` from `false` to `true`. Keep `reversion: true` and the 180 deg static transform. A 180 deg rotation is its own inverse, so only the mirror needed changing.

## 2. IMU all zeros: wrong Rosmaster_Lib version

**Symptom.** `imu_filter_madgwick` logs `Still waiting for data on topic /imu/data_raw`. After fixing remaps, `/imu/imu_raw` publishes at about 19 Hz but every field is 0.0, including gravity. Voltage (12.1 V) and firmware version (3.6) read correctly.

**Test.** Stop the base so the serial port is free, then:

```python
from Rosmaster_Lib import Rosmaster
import Rosmaster_Lib, time, collections
print(Rosmaster_Lib.__file__)
seen = collections.Counter()
name = [n for n in dir(Rosmaster) if "parse" in n.lower()][0]
orig = getattr(Rosmaster, name)
def wrap(self, t, d):
    seen[t] += 1
    return orig(self, t, d)
setattr(Rosmaster, name, wrap)
b = Rosmaster(com="/dev/yahboom_controller")
b.create_receive_threading()
time.sleep(3)
print({hex(k): v for k, v in seen.items()})
```

The board sends `0x0A` (speed), `0x0C` (attitude), `0x0D` (encoders) and `0x0E` (ICM raw IMU). Python 3 was loading `Rosmaster_Lib` **2.3.3** from `/usr/local/lib/python3.6/dist-packages/`, which has no handler for `0x0E`. Version 3.3.9 (shipped in `~/py_install`) handles it.

**Fix.**

```bash
sudo mkdir -p /usr/local/lib/python3.6/old_eggs
sudo mv /usr/local/lib/python3.6/dist-packages/Rosmaster_Lib-2.3.3-py3.6.egg /usr/local/lib/python3.6/old_eggs/
sudo sed -i '/Rosmaster_Lib-2.3.3/d' /usr/local/lib/python3.6/dist-packages/easy-install.pth
cd ~/py_install && sudo python3 setup.py install
python3 -c "import Rosmaster_Lib; print(Rosmaster_Lib.__file__)"   # must show 3.3.9
```

After the fix, at rest: accel about `(-0.15, 0.07, -9.67)` m/s^2, gyro near zero. Gyro yaw rate is positive for a counterclockwise turn (REP 103 correct). Accel z is negative (opposite of REP 103), which is why the EKF does not fuse absolute orientation (see 4).

## 3. IMU filter remaps did not match

**Symptom.** Same `Still waiting for data on topic /imu/data_raw` warning. `rostopic info /imu/imu_data` shows a publisher but no messages.

**Cause.** `imu_filter_madgwick` subscribes to `imu/data_raw` and publishes `imu/data`. The original launch remapped `/sub_imu` and `/pub_imu`, which the node never uses.

**Fix.** In `bringup_min.launch`:

```xml
<remap from="imu/data_raw" to="/imu/imu_raw"/>
<remap from="imu/data" to="/imu/imu_data"/>
```

## 4. EKF fusing a flipped absolute orientation

With accel z negative, Madgwick believes the robot is upside down, so its absolute yaw turns the opposite way to the raw gyro rate. Fusing both gives the EKF two contradictory headings.

**Fix.** In `robot_localization.yaml`, fuse only gyro yaw rate from the IMU:

```yaml
imu0_config: [false, false, false,
              false, false, false,
              false, false, false,
              false, false, true,
              false, false, false]
```

`two_d_mode: true` is already set.

## 5. Navigation config fighting the robot

| Problem | Effect | Fix |
|---|---|---|
| `yocs_velocity_smoother` between move_base and the driver | passes only `linear.x` and `angular.z`; DWA strafe commands were dropped, so the robot drove a different path than planned | removed; move_base publishes `/cmd_vel` directly |
| `yaw_goal_tolerance: 6.28` | any final heading counted as success | `0.15` |
| AMCL 1000 to 4000 particles, 200 beams, update every 1 cm, `transform_tolerance 2.0` | Nano falls behind; stale pose accepted | 300 to 1500 particles, 120 beams, update every 5 cm / 0.05 rad, `laser_sigma_hit 0.1`, `transform_tolerance 0.5` |
| `oscillation_timeout 5.0` | a 90 deg turn at 0.3 rad/s takes about 5 s and moves 0 m, so goals aborted as "oscillating" | `20.0` |
| strafing on (`holonomic_robot: true`, `max_vel_y 0.05`) | sideways crab on glossy hardwood, where Mecanum rollers slip most | strafing off, reverse kept (`min_vel_x -0.05`) |
| `sim_time 1.0`, `forward_point_distance 0.1` | with strafing off, a 1 s turn at 0.3 rad/s barely changes the score, so the robot sat facing the wrong way until timeout | `sim_time 2.5`, `forward_point_distance 0.3` |
| `xy_goal_tolerance 0.20` then `0.08`, with `latch_xy_goal_tolerance: true` | robot stopped at the first point inside the circle, always short on the approach side (5 to 6 in) | `0.04` |
| `acc_lim_x 0.5`, `acc_lim_theta 2.0` | abrupt starts and stops slid the wheels; final heading off by about 20 deg | `0.25`, `0.8` |

## 6. Gmapping range too short

`maxUrange 3.0` discarded most returns in a room larger than 6 m, so scan matching had little to hold onto. Raised to `maxUrange 6.0`, `maxRange 8.0`.

## Not a cause: wheel odometry

Measured with `scripts/odom_scale.py`: 2.017 m reported over a 2.000 m tape-measured drive (0.8%). A first 0.7 m run suggested 3%, which was tape-reading error over a short distance. `linear_scale_x` stays at 1.0.

## Not a cause: serial port contention

`joy.py` was not running (`ps aux | grep -E "joy.py|Mcnamu"`), so nothing competed with the driver for `/dev/yahboom_controller`.

## Network change gotcha

`~/.bashrc` hardcodes `ROS_MASTER_URI` and `ROS_IP`. After moving the Nano to a new Wi-Fi network every ROS command failed with `Unable to contact my own server at [http://OLD_IP:...]`. Update both lines and `source ~/.bashrc` in every open session. `start_mapping.sh` and `start_nav.sh` export these themselves.
