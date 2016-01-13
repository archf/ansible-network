#!/bin/sh

# requence of commands to validate ntpd clients and
# server behavior

# check sources
echo 'display sources information:'
echo
ntpq -p
echo
echo 'show sysinfo':
echo
ntpdc -c sysinfo
echo
echo 'show systats':
echo
ntpdc -c sysstats
echo
echo 'show iostats':
echo
ntpdc -c iostats
echo
echo 'show interface stats':
echo
# ntpdc -c ifstats
echo
echo 'show timerstats':
echo
ntpdc -c timerstats
echo
echo 'traffic counts collected and maintained by the monitor facility':
echo
ntpdc -c monlist
