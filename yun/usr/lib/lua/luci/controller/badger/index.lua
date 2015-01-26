module("luci.controller.badger.index", package.seeall)

function log(msg)
    if (type(msg) == "table") then
        for key, val in pairs(msg) do
            log('{')
            log(key)
            log(':')
            log(val)
            log('}')
        end
    else
        luci.sys.exec("logger -t luci \"" .. tostring(msg) .. '"')
    end
end

function index()
    entry({ "admin", "badger" }, alias("admin", "badger", "list"), _("Badger"), 90).index = true
    entry({ "admin", "badger", "list" }, call("users_list"), _("List of badges"), 10)
    entry({ "admin", "badger", "last_logged" }, call("last_logged"), _("Last logged badges"), 20)
    entry({ "admin", "badger", "configuration" }, cbi("badger/conf"), _("Configuration"), 30).dependent = false
    entry({ "admin", "badger", "toggle" }, call("user_toggle"), nil, 1)
    entry({ "admin", "badger", "new" }, call("user_new"), nil, 1)
    entry({ "admin", "badger", "edit" }, call("user_edit"), nil, 1)
    entry({ "admin", "badger", "save" }, call("user_save"), nil, 1)
end

function users_list()
    local sqlite3 = require("lsqlite3")
    local db = sqlite3.open("/root/logger.db")
    local select_stmt = assert(db:prepare("SELECT * FROM users"))
    local ctx = {
        users = {}
    }
    for row in select_stmt:nrows() do
        ctx.users[row.id] = row
    end

    luci.template.render("badger/list", ctx)
end

function back_home()
    luci.http.redirect(luci.dispatcher.build_url("admin/badger"))
end

function user_toggle()
    local user_id = luci.http.formvalue("user_id")
    if (user_id == nil or user_id == "") then
        return back_home()
    end

    local sqlite3 = require("lsqlite3")
    local db = sqlite3.open("/root/logger.db")

    local select_stmt = assert(db:prepare("SELECT id, enabled FROM users WHERE ID = ?"))
    select_stmt:bind_values(user_id)
    if (sqlite3.ROW ~= select_stmt:step()) then
        return back_home()
    end
    local user = select_stmt:get_named_values()

    local new_enabled_value = 1
    if (user.enabled == 1) then
        new_enabled_value = 0
    end

    local toggle_stmt = assert(db:prepare("UPDATE users SET enabled = ? WHERE id = ?"))
    toggle_stmt:bind_values(new_enabled_value, user_id)
    toggle_stmt:step()
    toggle_stmt:finalize()

    back_home()
end

function _user_edit(user)
    luci.template.render("badger/edit", { user = user })
end

function user_new()
    _user_edit({})
end

function user_edit()
    local user_id = luci.http.formvalue("user_id")
    if (user_id == nil or user_id == "") then
        return back_home()
    end

    local sqlite3 = require("lsqlite3")
    local db = sqlite3.open("/root/logger.db")

    local select_stmt = assert(db:prepare("SELECT * FROM users WHERE ID = ?"))
    select_stmt:bind_values(user_id)
    if (sqlite3.ROW ~= select_stmt:step()) then
        return back_home()
    end
    local user = select_stmt:get_named_values()

    _user_edit(user)
end

function user_save()
    local user_id = luci.http.formvalue("user_id")
    local name = luci.http.formvalue("name")
    local rfid = luci.http.formvalue("rfid")

    local sqlite3 = require("lsqlite3")
    local db = sqlite3.open("/root/logger.db")

    if (user_id == nil or user_id == "0" or user_id == "") then
        local insert_stmt = assert(db:prepare("INSERT INTO users (name, rfid, enabled) VALUES (?, ?, 1)"))
        insert_stmt:bind_values(name, rfid)
        insert_stmt:step()
        insert_stmt:finalize()
    else
        local update_stmt = assert(db:prepare("UPDATE users SET name = ?, rfid = ? WHERE id = ?"))
        update_stmt:bind_values(name, rfid, user_id)
        update_stmt:step()
        update_stmt:finalize()
    end

    back_home()
end

function last_logged()
    local sqlite3 = require("lsqlite3")
    local db = sqlite3.open("/root/logger.db")
    local select_stmt = assert(db:prepare("select lb.id, u.name, lb.rfid, lb.logged_at from logged_badges lb left outer join users u on (lb.user_id = u.id) limit 20 offset (select count(*) from logged_badges) - 20"))
    local ctx = {
        logged_badges = {}
    }
    local i = 1
    for row in select_stmt:nrows() do
        ctx.logged_badges[i] = row
        i = i + 1
    end

    luci.template.render("badger/last_logged", ctx)
end
