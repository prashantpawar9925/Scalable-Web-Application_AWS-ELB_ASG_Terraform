#!/bin/bash
apt-get update
apt-get install -y apache2
cd /var/www/html
echo This is Web Application $(hostname) >index.html


