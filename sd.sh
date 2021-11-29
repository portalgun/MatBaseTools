sd(){       set '' "$1" '' "${2?sd() requires two arguments!}"
            while [ "$#" -gt 2 ]
            do    [  "${1:--L}" "${2:--L}" ${3:+"$4"} ] &&
                  [  "${1:--L}" ${3:+"-L"} "${3:-$4}" ] &&
                  [  "${2:-$3}" -ef "$4"/. ] && return  || ${1:+"return"}
                  set "$@" "$2";shift 2;set ! "$@"
            done  3>/dev/null 2>&"$((${#DBG}?2:3))"
    }
