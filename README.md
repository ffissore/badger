# BADGER

Badger is a badge (RFID) reader application built with the Arduino Yun and the Adafruit NFC Shield.

It was made to track employees entraces and exits.

Every time a known badge makes the Badger bip, its number and associated description/name are added to a local storage 
of logged badges. Every 10 minutes this storage is backupped to a configured Google Spreadsheet.

This way, once set up, you can forget about the Badger and give access to that Google Spreadsheet to someone of the HR office.

# SETUP

Ensure you're running the latest and greatest OS version for your Yun: http://www.arduino.cc/en/Main/Software#other

Connect your Yun to your network using an ethernet cable: replace IP_ADDRESS below with the actual IP of your Yun.

From a terminal, run the following command

`scp -r yun/* root@IP_ADDRESS:/`

SSH into the Yun and run:

```bash
opkg update
#install additional packages
opkg install python-sqlite3 sqlite3-cli python-openssl python-expat lsqlite3
cd /tmp
wget --no-check-certificate https://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/oldpackages/python-crypto_2.6-1_ar71xx.ipk
opkg install python-crypto_2.6-1_ar71xx.ipk
cd -
#resets the 32u4 at the end of the boot
sed -i 's/#reset-mcu/reset-mcu/g' /etc/rc.local
#precompile python code for a faster start up
python -OO -m py_compile *.py gspread/*.py oauth2client/*.py httplib2/*.py
#synchronize google spreadsheet every 10 minutes
echo '*/10 * * * * /root/sync' > /etc/crontabs/root
```

In order to add additional security, please run the following commands as well:

```bash
#stop the webserver from listening to port 80: port 443 (https) remains active
sed -i 's/\tlist listen_http\t0.0.0.0:80/#\tlist listen_http\t0.0.0.0:80/g' /etc/config/uhttpd
#disables wifi: too easy to crack
uci set wireless.radio0.disabled=1
uci commit
#having disabled wifi, there's no need to check if it's working
sed -i 's/wifi-live-or-reset/#wifi-live-or-reset/g' /etc/rc.local
```

# CREATING A GOOGLE API KEY

In order to give your Badger access to your spreadsheet, you need to create a `client_email` + `private_key` pair. 
Follow [the instructions](http://gspread.readthedocs.org/en/latest/oauth2.html) until you download a `.json` file. Open that `.json` file 
and collect `client_email` and `private_key` keys values.

# CONFIGURATION

Access your Yun web panel, click "Configure", click "advanced control panel", click on the "Badger" tab.

Configure the Badger by specifying the title of the Google Spreadsheet, and `client_email` and `private_key` previously set up.

Fill the badges database: add RFIDs and associate a description/name to each of them.

# FINAL TEST

Put one of the badges near the Badger.

When everything goes well, the GREEN led blinks and then stays lit for a second: a short beep is heard.

When there's something wrong, the GREEN led blinks and then the RED led lits for a couple of seconds: a long beep is heard. 
Two possible problems may be the cause: the badge was unknown or the disk space of the Yun is full. In the latter case, 
move the database to an uSD card and modify the python code accordingly.

# UPGRADING FROM VERSION 1.0.0

Create a Google API key (see previous paragraph)

Copy all the files

`scp -r yun/* root@IP_ADDRESS:/`

Install an additional package:

```bash
cd /tmp
wget --no-check-certificate https://downloads.openwrt.org/barrier_breaker/14.07/ar71xx/generic/packages/oldpackages/python-crypto_2.6-1_ar71xx.ipk
opkg install python-crypto_2.6-1_ar71xx.ipk
cd -
```

Recompile python scripts:

`python -OO -m py_compile *.py gspread/*.py oauth2client/*.py httplib2/*.py`

Access webpanel and configure Badger using the information contained in the `.json` file downloaded when you created a Google API key

# CREDITS

This project was *inspired* by [FablabDoorman](https://github.com/FablabTorino/FablabDoorman). Thanks to @Fede85 and the guys at [FabLab Torino](http://fablabtorino.org/) for their awesome work!

# LICENSE

Badger, an RFID tracker made with Arduino
Copyright (C) 2015 Federico Fissore

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

