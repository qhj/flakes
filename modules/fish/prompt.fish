set fish_greeting

set -g __fish_git_prompt_showdirtystate true
set -g __fish_git_prompt_showstashstate true
set -g __fish_git_prompt_showuntrackedfiles true
set -g __fish_git_prompt_showupstream informative
set -g __fish_git_prompt_show_informative_status true
set -g __fish_git_prompt_showcolorhints true
set -g __fish_git_prompt_char_stateseparator ''
set -g __fish_git_prompt_char_stagedstate ' +'
set -g __fish_git_prompt_char_invalidstate ' ~'
set -g __fish_git_prompt_char_dirtystate ' !'
set -g __fish_git_prompt_char_untrackedfiles ' ?'
set -g __fish_git_prompt_char_stashstate ' *'
set -g __fish_git_prompt_char_upstream_prefix ' '
set -g __fish_git_prompt_char_upstream_ahead '↑'
set -g __fish_git_prompt_char_upstream_behind '↓'
set -g __fish_git_prompt_char_upstream_diverged '↕'
set -g __fish_git_prompt_color_branch brgreen
set -g __fish_git_prompt_color_invalidstate brred
set -g __fish_git_prompt_color_dirtystate bryellow
set -g __fish_git_prompt_color_stagedstate bryellow
set -g __fish_git_prompt_color_stashstate brgreen
set -g __fish_git_prompt_color_untrackedfiles brblue
set -g __fish_git_prompt_color_upstream brgreen
set -g __fish_git_prompt_color_merging brred

function fish_prompt
    set -l last_status $status

    set_color brblack
    printf '%s ' (date '+%H:%M:%S')

    if set -q IN_NIX_SHELL
        set_color brcyan
        printf ' %s ' $IN_NIX_SHELL
    end

    if fish_is_root_user
        set_color brred
        printf '%s' $USER
        set_color normal
        printf '@'
    end

    set_color brmagenta
    printf '%s ' (prompt_hostname)

    set_color brblue
    printf '%s' (prompt_pwd)

    fish_git_prompt ' %s'

    set_color normal
    printf ' '

    if test $last_status -eq 0
        set_color normal
        printf '> '
    else
        set_color brred
        printf '[%s]> ' $last_status
    end
    set_color normal
end

function fish_right_prompt
end
