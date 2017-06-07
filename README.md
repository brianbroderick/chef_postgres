This repo is designed to make it easy to install Postgres using Chef (or Amazon Opsworks).
Currently, it's geared towards Ubuntu, but will eventually be expanded to support other Linux Distros.  

The target Ubuntu version is specified in custom JSON; for example for Ubuntu 16.04, use: 

```
{
  "postgresql":  {
    "release_apt_codename": "xenial",
    "version": "9.6" 
  }
}
```
