#!/bin/bash
OF=/mnt/data/backups/pg-$(date +%F).sql
pg_dump -U postgres -d app > $OF
gzip $OF
echo "Finished"