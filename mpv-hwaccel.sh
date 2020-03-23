#!/bin/bash -e

#display 32 960x540 vidoes for dual 4K monitor

export DISPLAY=:0
cp 960.h264 /dev/shm && cd /dev/shm
for y in {0..3}; do for x in {0..3};do mpv 960.h264 -loop --no-border --geometry 960x540+$((3840+x*960))+$((y*540)) >/dev/null 2>&1 &done;done
sleep 1
for y in {0..3}; do for x in {0..3};do mpv 960.h264 -loop --no-border --geometry 960x540+$((x*960))+$((y*540)) >/dev/null 2>&1 &done;done
