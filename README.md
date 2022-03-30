# Introduction
A bash script to log in CityU CS [network captive portal](http://cp.cs.cityu.edu.hk:16978/login.html?).

# Usage

1. Modify the login script to replace the EID and PASSWORD in the following lines:
```
9:EID=foo
10:PASSWORD=bar
```
2. Run script directly (without option)
```
./autologin.sh
```
or run script with one option, `-h`, `-c`, `-i`, or `-o`.

```
Syntax: ./autologin.sh [-h|c|i|o]
Options:
h     Print this help.
c     Check internet connection and log in network captive portal.
i     Log in network captive portal.
o     Log out network captive portal.
```
Hint: `-c` option can be used with [cron job](https://www.hostinger.com/tutorials/cron-job) to automatically check internet connection and log in network captive portal.

### NOTE
You need to manually lower SSL security level on Ubuntu 20.04 or above in order to connect to network captive portal. Please refer to the comments at the top of this login script for more details.
