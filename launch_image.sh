#!/bin/bash

BUS=$(lsusb | grep 8086 | cut -d " " -f 2)
PORT=$(lsusb | grep 8086 | cut -d " " -f 4 | cut -d ":" -f 1)

if [ ! -z "$PORT" ]
then
sudo docker run \
  --rm \
  --volume /dev/bus/usb/$BUS/$PORT:/dev/bus/usb/$BUS/$PORT \
  --device-cgroup-rule "c 189:* rmw" \
  --device=/dev/video0:/dev/video0 --device=/dev/video1:/dev/video1 \
  --device=/dev/video2:/dev/video2 --device=/dev/video3:/dev/video3 \
  --device=/dev/video4:/dev/video4 --device=/dev/video5:/dev/video5 \
  --device=/dev/HID-SENSOR-2000e1.4.auto:/dev/HID-SENSOR-2000e1.4.auto \
  --gpus all --shm-size=8g --net=host -it -e DISPLAY=192.168.8.162:10 -e GDK_BACKEND=x11 -e XAUTHORITY=/root/.Xauthority -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v $HOME/.Xauthority_docker:/root/.Xauthority:rw -v /home/jet/robotics/semantic_navigation/docker_fcaf3d/root:/mmdetection3d/data \
  realsense_ros_packages_set_up
fi
