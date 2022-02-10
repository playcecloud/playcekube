#  PlayceKube commander

_comp_playcekube () {
  if [ "${cword}" == "1" ]; then
    COMPREPLY=( $(compgen -W "k8s kubernetes kubectl addon helm" -- ${cur}) )
  fi

  if [ "${cword}" -lt "2" ]; then
    return 0;
  fi

  case ${words[1]} in
    k8s | kubernetes | kubectl)
      COMPREPLY=( $(compgen -W "list install" -- ${cur}) )

      if [ "${cword}" -lt "3" ]; then
        return 0;
      fi

      case ${words[2]} in
        install)
          COMPREPLY=( $(compgen -W "-e -f" -- ${cur}) )
          ;;
        *)
          COMPREPLY=()
          ;;
      esac

      if [ "${prev}" == "-f" ]; then
        COMPREPLY=( $(compgen -f -- ${cur}) )
        compopt -o plusdirs
      fi
    ;;
    addon | helm)
      COMPREPLY=( $(compgen -W "list install-list" -- ${cur}) )

      if [ "${cword}" -lt "3" ]; then
        return 0;
      fi

      case ${words[2]} in
        install-list)
          COMPREPLY=( $(compgen -W "-A -n" -- ${cur}) )
          ;;
        *)
          COMPREPLY=()
          ;;
      esac

      if [ "${prev}" == "-f" ]; then
        COMPREPLY=( $(compgen -f -- ${cur}) )
        compopt -o plusdirs
      fi
    ;;
  esac

  return 0;
}

_comp_init_playcekube()
{
    COMPREPLY=()
    _get_comp_words_by_ref "$@" cur prev words cword
}

_comp_start_playcekube()
{
  local cur prev words cword

  if declare -F _init_completion >/dev/null 2>&1; then
    _init_completion -s || return
  else
    _comp_init_playcekube -n "=" || return
  fi

  _comp_playcekube
}

complete -F _comp_start_playcekube playcekube

