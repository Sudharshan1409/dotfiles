-- Monitor configuration and auto-profile loading
local home = os.getenv("HOME") or "/home/sudharshan"

-- Fallback default monitor rule
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- Load generated monitor profile if present
local gen_file = home .. "/.config/hypr/monitors.gen.conf"
local f = io.open(gen_file, "r")
if f then
    for line in f:lines() do
        local target = line:match("^source%s*=%s*(.+)$")
        if target then
            target = target:gsub("^~", home)
            local tf = io.open(target, "r")
            if tf then
                for tline in tf:lines() do
                    local mon_rule = tline:match("^%s*monitor%s*=%s*(.+)$")
                    if mon_rule then
                        local parts = {}
                        for p in mon_rule:gmatch("[^,]+") do
                            table.insert(parts, p:match("^%s*(.-)%s*$"))
                        end
                        if #parts >= 1 then
                            hl.monitor({
                                output   = parts[1],
                                mode     = parts[2] or "preferred",
                                position = parts[3] or "auto",
                                scale    = parts[4] or "auto",
                            })
                        end
                    end

                    local ws_rule = tline:match("^%s*workspace%s*=%s*(.+)$")
                    if ws_rule then
                        local ws_id, mon_name = ws_rule:match("^([^,]+)%s*,%s*monitor:(.+)$")
                        if ws_id and mon_name then
                            hl.workspace_rule({
                                workspace = ws_id:match("^%s*(.-)%s*$"),
                                monitor   = mon_name:match("^%s*(.-)%s*$"),
                            })
                        end
                    end
                end
                tf:close()
            end
        end
    end
    f:close()
end
