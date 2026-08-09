# Vela Makefile tab-completion
_vela_make() {
    local cur prev boards
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    boards="vela"
    local targets="all build image rebuild-image sdk esdk shell swu flash \
                   kas-image sdk-image esdk-image ensure-image ensure-sdk-image \
                   ensure-esdk-image deploy-images deploy-sdk deploy-esdk deploy-swu \
                   clean clean-build clean-docker clean-all completion help"
    case "${prev}" in
        image|build|rebuild-image|sdk|esdk|shell|flash)
            COMPREPLY=( $(compgen -W "${boards}" -- "${cur}") )
            return 0
            ;;
    esac
    COMPREPLY=( $(compgen -W "${targets} ${boards}" -- "${cur}") )
    return 0
}
complete -F _vela_make make
