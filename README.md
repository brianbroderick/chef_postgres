This repo is designed to make it easy to install Postgres using Chef (or Amazon Opsworks).
Currently, it supports Ubuntu, but will eventually be expanded to support other Linux Distros. 
It's also geared towards using Postgres >= 9.1. 

To change the default settings, pass in custom JSON.  The below JSON represents the defaults.

```
{
  "postgresql":  {
    "release_apt_codename": "xenial",
    "version": "9.6",
    "workload": "oltp" 
  }
}
```

For workload, the options are:

"dw" - Data Warehouse
  * Generally I/O or RAM intensive, though aggregate queries can use a lot of CPU
  * Large bulk inserts
  * Large complex reporting queries
  * Also called "Business Intelligence" or "BI"

"oltp" - Online Transaction Processing
  * Generally CPU or I/O intensive
  * DB can be slightly larger than RAM 
  * Writes are usually small
  * Some long transactions and complex read queries

"web" - Web Application
  * Generally CPU or I/O intensive
  * DB much smaller than RAM
  * Mostly simple queries

"mixed" - Mixed DW and OLTP characteristics
  * A generic workhorse

"desktop" - Not a dedicated database
  * A dev environment
