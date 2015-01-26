# Badger, an RFID tracker made with Arduino
# Copyright (C) 2015 Federico Fissore
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

from sys import argv
import sqlite3
import os

source_dir = os.path.dirname(os.path.abspath(__file__))
conn = sqlite3.connect(os.path.join(source_dir, "logger.db"))
cursor = conn.cursor()

cursor.execute(
    "CREATE TABLE IF NOT EXISTS logged_badges(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, user_id INTEGER, rfid TEXT NOT NULL, logged_at TEXT NOT NULL, in_sync INTEGER NOT NULL DEFAULT 0)")
cursor.execute("CREATE TABLE IF NOT EXISTS users(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, name TEXT NOT NULL, rfid TEXT NOT NULL, enabled INTEGER NOT NULL DEFAULT 1)")


def find_user_id(rfid):
    cursor.execute("SELECT id FROM users WHERE rfid = ? AND enabled = 1", (rfid, ))
    rows = cursor.fetchall()
    if len(rows) > 0:
        return rows[0][0]

    return None


rfid = "".join(argv[1])
user_id = find_user_id(rfid)

cursor.execute("INSERT INTO logged_badges(user_id, rfid, logged_at) VALUES (?, ?, datetime('now', 'localtime'));", (user_id, rfid))

conn.commit()
conn.close()

if user_id is None:
    exit(1)
