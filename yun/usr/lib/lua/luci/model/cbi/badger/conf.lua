m = Map("badger", "Configuration")

s = m:section(TypedSection, "badger")
s.anonymous = true

s:option(Value, "spreadsheet_title", translate("Google Spreadsheet Title"))
s:option(Value, "google_usr", translate("Google Username"))
pwd = s:option(Value, "google_pwd", translate("Google Password"))
pwd.password = true

return m