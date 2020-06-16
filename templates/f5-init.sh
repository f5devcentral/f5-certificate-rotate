#!/bin/bash

#wait for big-ip
sleep 120

#admin config
tmsh modify auth user ${username} { password ${password} }
tmsh modify auth user ${username} shell bash
tmsh modify sys global-settings gui-setup disabled

tmsh save sys config