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

import sqlite3
import os
import gspread
from oauth2client.client import SignedJwtAssertionCredentials
scope = ['https://spreadsheets.google.com/feeds']

source_dir = os.path.dirname(os.path.abspath(__file__))
conn = sqlite3.connect(os.path.join(source_dir, "logger.db"))

fetch_cursor = conn.cursor()

fetch_cursor.execute("SELECT count(*) FROM logged_badges WHERE in_sync = 0")
if fetch_cursor.fetchone()[0] is 0:
    conn.close()
    exit(0)

import subprocess

google_client_email = subprocess.check_output(["uci", "get", "badger.@badger[0].google_client_email"]).strip()
google_private_key = subprocess.check_output(["uci", "get", "badger.@badger[0].google_private_key"]).strip()
google_spreadsheet_title = subprocess.check_output(["uci", "get", "badger.@badger[0].spreadsheet_title"]).strip()

google_private_key = google_private_key.decode('unicode_escape')

credentials = SignedJwtAssertionCredentials(google_client_email, google_private_key, scope)

# Login with your Google account
gc = gspread.authorize(credentials)

# Open a worksheet from spreadsheet with one shot
wks = gc.open(google_spreadsheet_title).sheet1

first_cell = wks.cell(1, 1)
if first_cell.value is "":
    wks.resize(1, 4)

    def make_cell(row, col, value):
        cell = wks.cell(row, col)
        cell.value = value
        return cell

    cells = [make_cell(1, 1, "ID"), make_cell(1, 2, "NAME"), make_cell(1, 3, "BADGE"), make_cell(1, 4, "TIME")]
    wks.update_cells(cells)

update_cursor = conn.cursor()
fetch_cursor.execute("SELECT l.id, u.name, l.rfid, l.logged_at FROM logged_badges l LEFT OUTER JOIN users u ON (u.id = l.user_id) WHERE l.in_sync = 0")

for row in fetch_cursor.fetchall():
    name = row[1] or ""
    print row[0], name, row[2], row[3]
    wks.append_row([row[0], name, row[2], row[3]])
    update_cursor.execute("UPDATE logged_badges SET in_sync = 1 WHERE id = ?", (row[0], ))
    conn.commit()

conn.close()

