function _tide_item_hostname
    if set -q SSH_TTY
        return
    end

    set -l host (prompt_hostname)

    test -n "$host"
    and _tide_print_item hostname $host
end
