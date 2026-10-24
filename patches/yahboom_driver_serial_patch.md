# Yahboom driver serial-port patch

## Why this patch is needed

With the default serial port the Yahboom chassis driver did not reach the expansion board. Symptoms:

- `/voltage` stayed 0.0
- `/vel_raw` stayed zero
- robot would not move from ROS
- `/odom` was useless

## Current fix: stable udev alias

Hardcoding `/dev/ttyUSB1` breaks whenever USB enumeration order changes. The driver now opens a udev alias:

```python
self.car = Rosmaster(com="/dev/yahboom_controller")
```

The alias comes from `udev/99-robot-usb.rules`:

```
SUBSYSTEM=="tty", ATTRS{idProduct}=="7523", SYMLINK+="yahboom_controller"
SUBSYSTEM=="tty", ATTRS{idProduct}=="ea60", SYMLINK+="ydlidar"
```

`7523` is the CH340 on the expansion board. `ea60` is the CP2102 on the Tmini Plus.

Install:

```bash
sudo cp udev/99-robot-usb.rules udev/99-ydlidar.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger
ls -l /dev/yahboom_controller /dev/ydlidar
```

## File to patch

`/home/jetson/yahboomcar_auto/src/yahboomcar_bringup/scripts/Mcnamu_driver.py`

Find `self.car = Rosmaster()` and change it to `self.car = Rosmaster(com="/dev/yahboom_controller")`.

Verify:

```bash
grep -n "self.car = Rosmaster" /home/jetson/yahboomcar_auto/src/yahboomcar_bringup/scripts/Mcnamu_driver.py
```

The driver also calls `self.car.set_car_type(10)`.

## Earlier version

The March version of this repo used `Rosmaster(com="/dev/ttyUSB1")`. That worked only while the board enumerated as `ttyUSB1`.

## Library version

The driver also needs `Rosmaster_Lib` 3.3.9 with board firmware 3.6. Version 2.3.3 talks to the board but returns zeros for the IMU. See `docs/07_root_causes_and_fixes.md`, section 2.
