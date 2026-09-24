local function readHostname()
    local hostname = noctalia.readFile("/proc/sys/kernel/hostname")
    if hostname == nil then
        return "?"
    end

    hostname = noctalia.string.trim(hostname)
    if hostname == "" then
        return "?"
    end

    return string.upper(hostname)
end

barWidget.setText(readHostname())
