#!/usr/bin/bash
sleep 30
su -l ubuntu
rails s -p 3000 -b 0.0.0.0 -d