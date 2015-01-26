# BADGER

Badger is a badge (RFID) reader application built with the Arduino Yun and Adafruit NFC Shield

It was made to track employees entraces and exits.

Every time a known badge makes the Badger bip, its number and associated description/name add added to a local storage of logged badges. Every 10 minutes this storage is backupped to a configured Google Spreadsheet.

This way, once set up, you can forget about the Badger and give access to the Google Spreadsheet to some at the HR office.

# SETUP

Ensure you're running the latest and greatest OS version for your Yun: http://arduino.cc/en/Main/Software#yun

Connect your Yun to your network using an ethernet cable: replace IP_ADDRESS below with the actual IP of your Yun.

From a terminal, run the following command

`scp -r yun/* root@IP_ADDRESS:/`

SSH into the Yun and run:

```
opkg update
opkg install python-sqlite3 sqlite3-cli python-openssl python-expat lsqlite3
sed -i 's/#reset-mcu/reset-mcu/g' /etc/rc.local
python -OO -m py_compile *.py gspread/*.py
echo '#*/10 * * * * /root/sync' > /etc/crontabs/root
```

In order to add additional security, please run the following commands as well:

```
sed -i 's/\tlist listen_http\t0.0.0.0:80/#\tlist listen_http\t0.0.0.0:80/g' /etc/config/uhttpd
uci set wireless.radio0.disabled=1
uci commit
sed -i 's/wifi-live-or-reset/#wifi-live-or-reset/g' /etc/rc.local
```

# CONFIGURATION

Access your Yun web panel, click "Configure", click "advanced control panel", click on the "Badger" tab

Configure the Badger by specifying the title of the Google Spreadsheet, username and password for its associated google account.

Fill the badges database: add RFIDs and give a name (or associate a description) to each of them.

# FINAL TEST

Put one of the badges near the Badger.

When everything goes well, the GREEN led blinks and then stays lit for a second and a short beep is heard.

When there's something wrong, the GREEN led blinks and then the RED led lits for a couple of seconds and a long beep is heard. Two possible problems may be the cause: the badge was unknown or the disk space of the Yun is full. In the latter case, move the database to an uSD card and modify the python code accordingly

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

