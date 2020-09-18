#!/bin/bash

set -e

tmsh run sys crypto check-cert | grep "demo" 

sleep 30

