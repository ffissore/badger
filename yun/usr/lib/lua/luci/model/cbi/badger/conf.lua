m = Map("badger", "Configuration")

s = m:section(TypedSection, "badger")
s.anonymous = true

s:option(Value, "spreadsheet_title", translate("Google Spreadsheet Title"))
s:option(Value, "google_client_email", translate("Google client_email"))
s:option(Value, "google_private_key", translate("Google private_key"))

return m
