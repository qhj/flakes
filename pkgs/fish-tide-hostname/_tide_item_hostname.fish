function _tide_item_hostname
    set -l host (prompt_hostname)

    test -n "$host"
    and _tide_print_item hostname $host
end
