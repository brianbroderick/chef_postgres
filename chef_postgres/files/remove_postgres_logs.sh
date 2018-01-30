#!/bin/bash

daystokeep='1'

find /var/log/postgresql/postgresql-2* -mtime +$daystokeep -exec rm {} \;
