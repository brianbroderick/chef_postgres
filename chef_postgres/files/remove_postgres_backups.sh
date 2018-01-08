#!/bin/bash
#make sure to set cron tab to run hourly
daystokeep='1'

find /mnt/data/backups/pg-2*.gz -mtime +$daystokeep -exec rm {} \;
