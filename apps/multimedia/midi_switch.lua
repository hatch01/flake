ardour({
    ["type"] = "session",
    name = "MIDI Auto Switch",
    category = "Utility",
    license = "MIT",
    author = "hatch01",
    description = [[Listens to MIDI Note On events and exclusively un-mutes one bus/track per matching event.

Routes are named "<prefix> <N>" (e.g. "Guitar 1 Bus", "Guitar 2 Bus", ...).
The mapping channel-note,channel-note,... is applied in order to routes 1..N.

To change the configuration: remove and re-add the script.]],
})

function sess_params()
    return {
        ["prefix"] = { title = "Log prefix", default = "midi-switch", optional = false },

        -- Naming pattern for routes
        ["route_prefix"] = {
            title = "Route name prefix (before number)",
            default = "Guitar 1 Bus",
            optional = false,
        },

        -- Number of routes
        ["count"] = { title = "Number of routes (N) — they are #1..#N", default = "3", optional = false },

        -- Mapping
        ["mapping"] = {
            title = "MIDI map: ch-note,ch-note,... (one per route)",
            default = "1-33,4-33,5-33",
            optional = false,
        },

        -- Port filters (use '.' to disable)
        ["port_filter"] = {
            title = "Port name MUST contain (use '.' for all)",
            default = "MIDI Control",
            optional = false,
        },
        ["port_exclude"] = {
            title = "Port name MUST NOT contain ('.' = none)",
            default = "LUA SCRIPTING",
            optional = false,
        },

        ["debug"] = {
            title = "Debug log (yes/no)",
            default = "no",
            optional = false,
        },
    }
end

function factory(params)
    local p = params or {}

    -- ---------- helpers ----------
    local function parse_yesno(v, default_yes)
        if v == nil or v == "" then
            return default_yes
        end
        v = string.lower(tostring(v))
        return (v == "yes" or v == "y" or v == "true" or v == "1" or v == "on")
    end

    local function parse_int(v, default)
        if v == nil or v == "" then
            return default
        end
        local n = tonumber(v)
        if n == nil then
            return default
        end
        return math.floor(n)
    end

    local function trim(s)
        if s == nil then
            return ""
        end
        return (s:gsub("^%s+", ""):gsub("%s+$", ""))
    end

    -- ---------- lecture des paramètres ----------
    local prefix = trim(p["prefix"])
    if prefix == "" then
        prefix = "midi-switch"
    end

    local debug_enabled = parse_yesno(p["debug"], true)

    -- Note : on garde les espaces internes au prefix
    -- mais on retire les vrais bouts de blanc de bord avec un trim "doux"
    local route_prefix = p["route_prefix"] or ""

    local count = parse_int(p["count"], 0)
    if count < 1 then
        count = 0
    end

    local port_filter = trim(p["port_filter"] or "")
    local port_exclude = trim(p["port_exclude"] or "")
    if port_filter == "." then
        port_filter = ""
    end
    if port_exclude == "." then
        port_exclude = ""
    end

    -- ---------- parse du mapping "ch-note,ch-note,..." ----------
    -- Renvoie une liste { {ch=1,note=33}, {ch=4,note=33}, ... }
    local function parse_mapping(s)
        local pairs_out = {}
        if s == nil or s == "" then
            return pairs_out
        end
        for token in string.gmatch(s, "[^,]+") do
            local tok = trim(token)
            if tok ~= "" then
                -- accepte "ch-note", "ch:note" et "ch/note"
                local a, b = tok:match("^(%d+)%s*[-:/]%s*(%d+)$")
                local ch, nt = tonumber(a), tonumber(b)
                if ch and nt and ch >= 1 and ch <= 16 and nt >= 0 and nt <= 127 then
                    table.insert(pairs_out, { ch = ch, note = nt })
                else
                    table.insert(pairs_out, { invalid = tok })
                end
            end
        end
        return pairs_out
    end

    local mapping_pairs = parse_mapping(p["mapping"] or "")

    -- ---------- construction du mapping final : route name <- ch+note ----------
    -- ROUTE_NAMES[i] = nom de la route i (1..count)
    -- MAP[ch][note] = "Route Name"
    local ROUTE_NAMES = {}
    local MAP = {}
    local valid_count = 0

    for i = 1, count do
        local rname = route_prefix .. " " .. tostring(i)
        table.insert(ROUTE_NAMES, rname)

        local m = mapping_pairs[i]
        if m == nil then
            print("[" .. prefix .. "] WARNING: no mapping provided for route #" .. i .. " (" .. rname .. ")")
        elseif m.invalid then
            print("[" .. prefix .. "] WARNING: invalid mapping token for route #" .. i .. " : " .. tostring(m.invalid))
        else
            MAP[m.ch] = MAP[m.ch] or {}
            if MAP[m.ch][m.note] then
                print(
                    string.format(
                        "[%s] WARNING: ch=%d note=%d already mapped to %q, overwriting with %q",
                        prefix,
                        m.ch,
                        m.note,
                        MAP[m.ch][m.note],
                        rname
                    )
                )
            end
            MAP[m.ch][m.note] = rname
            valid_count = valid_count + 1
        end
    end

    if #mapping_pairs > count then
        print(
            string.format(
                "[%s] WARNING: mapping has %d entries but count=%d — extra entries ignored",
                prefix,
                #mapping_pairs,
                count
            )
        )
    end

    -- ---------- helpers ----------
    local function dbg(msg)
        if debug_enabled then
            print("[" .. prefix .. "] " .. msg)
        end
    end

    local function port_matches(name)
        if port_filter ~= "" and not string.find(name, port_filter, 1, true) then
            return false
        end
        if port_exclude ~= "" and string.find(name, port_exclude, 1, true) then
            return false
        end
        return true
    end

    -- ---------- état persistant ----------
    local last_target = nil

    local function set_exclusive_target(target)
        if not target then
            return
        end
        if target == last_target then
            return
        end

        dbg("switch -> " .. target)

        for _, route_name in ipairs(ROUTE_NAMES) do
            local r = Session:route_by_name(route_name)
            if r == nil or r:isnil() then
                dbg("WARNING route not found: [" .. route_name .. "]")
            else
                local val = (route_name == target) and 0 or 1
                local mc = r:mute_control()
                if mc == nil or mc:isnil() then
                    dbg("WARNING no mute control on: [" .. route_name .. "]")
                else
                    local ok, err = pcall(function()
                        mc:set_value(val, PBD.GroupControlDisposition.NoGroup)
                    end)
                    if not ok then
                        dbg(string.format("ERROR set_value %s -> mute=%d : %s", route_name, val, tostring(err)))
                    end
                end
            end
        end

        last_target = target
    end

    -- ---------- log de démarrage ----------
    print(string.format("[%s] started — count=%d, %d valid mapping(s)", prefix, count, valid_count))
    for i, rname in ipairs(ROUTE_NAMES) do
        local m = mapping_pairs[i]
        if m and not m.invalid then
            print(string.format("[%s]   #%d : ch=%d note=%d -> %q", prefix, i, m.ch, m.note, rname))
        else
            print(string.format("[%s]   #%d : (no mapping) -> %q", prefix, i, rname))
        end
    end
    print(
        string.format(
            "[%s] filter: port_must_contain=%q port_must_not_contain=%q debug=%s",
            prefix,
            port_filter,
            port_exclude,
            tostring(debug_enabled)
        )
    )

    if valid_count == 0 then
        print("[" .. prefix .. "] WARNING: no valid mapping, script will be idle.")
    end

    -- ---------- callback temps-réel ----------
    return function(n_samples)
        if valid_count == 0 then
            return
        end

        local _, t = Session:engine():get_ports(ARDOUR.DataType.midi(), ARDOUR.PortList())

        for port in t[2]:iter() do
            if not port:receives_input() then
                goto next_port
            end

            local midiport = port:to_midiport()
            if midiport:isnil() then
                goto next_port
            end

            local port_name = port:name()
            if not port_matches(port_name) then
                goto next_port
            end

            local mb = midiport:get_midi_buffer(n_samples)
            local events = mb:table()

            for _, e in pairs(events) do
                local ev = e:buffer():array()
                local sz = e:size()

                if sz >= 3 then
                    local status = ev[1]
                    local typ = status >> 4
                    local ch = (status & 0x0f) + 1
                    local note = ev[2]
                    local vel = ev[3]

                    -- Note On avec vélocité >= 1 (filtre Note Off implicite)
                    if typ == 0x9 and vel >= 1 then
                        local target = MAP[ch] and MAP[ch][note] or nil
                        if target then
                            dbg(string.format("trigger from port=%s ch=%d note=%d vel=%d", port_name, ch, note, vel))
                            set_exclusive_target(target)
                        end
                    end
                end
            end

            ::next_port::
        end
    end
end
