# Git bash for windows powerline theme
#
# Licensed under MIT
# Based on https://github.com/Bash-it/bash-it and https://github.com/Bash-it/bash-it/tree/master/themes/powerline
# Some ideas from https://github.com/speedenator/agnoster-bash
# Git code based on https://github.com/joeytwiddle/git-aware-prompt/blob/master/prompt.sh
# More info about color codes in https://en.wikipedia.org/wiki/ANSI_escape_code

MULTILINE="YES" # set to "YES" to put add a \n before and after the prompt
SHORT_USER_INFO="YES" # set to "YES" to omit the hostname
SHORT_CWD="YES" # set to "YES" to show only the basename of the CWD
PADDING=" " # use this character sequence to pad the segments around the separators

PROMPT_CHAR=${POWERLINE_PROMPT_CHAR:=""}
POWERLINE_LEFT_SEPARATOR="${PADDING}"
POWERLINE_PROMPT="last_status user_info cwd npm scm"

USER_INFO_SSH_CHAR="${PADDING}"
USER_INFO_PROMPT_COLOR="C Bl"

NPM_PROMPT_COLOR="Y Bl"

SCM_GIT_CHAR="${PADDING}"
SCM_PROMPT_CLEAN=""
SCM_PROMPT_DIRTY="*"
SCM_PROMPT_AHEAD="↑"
SCM_PROMPT_BEHIND="↓"
SCM_PROMPT_CLEAN_COLOR="G Bl"
SCM_PROMPT_DIRTY_COLOR="R Bl"
SCM_PROMPT_AHEAD_COLOR=""
SCM_PROMPT_BEHIND_COLOR=""
SCM_PROMPT_STAGED_COLOR="Y Bl"
SCM_PROMPT_UNSTAGED_COLOR="R Bl"
SCM_PROMPT_COLOR=${SCM_PROMPT_CLEAN_COLOR}

CWD_PROMPT_COLOR="B Bl"

STATUS_PROMPT_COLOR="Bl R B"
STATUS_PROMPT_ERROR="✘"
STATUS_PROMPT_ERROR_COLOR="Bl R B"
STATUS_PROMPT_ROOT="⚡"
STATUS_PROMPT_ROOT_COLOR="Bl Y B"
STATUS_PROMPT_JOBS="●"
STATUS_PROMPT_JOBS_COLOR="Bl Y B"

function __color {
  local bg
  local fg
  local mod
  case $1 in
     'Bl') bg=40;;
     'R') bg=41;;
     'G') bg=42;;
     'Y') bg=43;;
     'B') bg=44;;
     'M') bg=45;;
     'C') bg=46;;
     'W') bg=47;;
     *) bg=49;;
  esac

  case $2 in
     'Bl') fg=30;;
     'R') fg=31;;
     'G') fg=32;;
     'Y') fg=33;;
     'B') fg=34;;
     'M') fg=35;;
     'C') fg=36;;
     'W') fg=37;;
     *) fg=39;;
  esac

  case $3 in
     'B') mod=1;;
     *) mod=0;;
  esac

  # Control codes enclosed in \[\] to not polute PS1
  # See http://unix.stackexchange.com/questions/71007/how-to-customize-ps1-properly
  echo "\[\e[${mod};${fg};${bg}m\]"
}

function __powerline_user_info_prompt {
  local user_info=""
  local color=${USER_INFO_PROMPT_COLOR}
  local hostname_escape="@\\h"
  [[ "$SHORT_USER_INFO" == "YES" ]] && hostname_escape=""
  if [[ -n "${SSH_CLIENT}" ]]; then
    user_info="${USER_INFO_SSH_CHAR}\u${hostname_escape}"
  else
    user_info="\u${hostname_escape}"
  fi
  [[ -n "${user_info}" ]] && echo "${PADDING}${user_info}${PADDING}|${color}"
}

function __powerline_cwd_prompt {
  local cwd_escape="\\w"
  [[ "$SHORT_CWD" == "YES" ]] && cwd_escape="\\W"
  echo "${cwd_escape}${PADDING}|${CWD_PROMPT_COLOR}"
}

function __powerline_npm_prompt {
  npm_package_file_name="package.json"
  npm_package_file=""
  git_top_level=""
  npm_name=""
  npm_version=""

  find_git_top_level() {
    git_top_level=$(git rev-parse --show-toplevel 2> /dev/null)
    return 0
  }

  find_npm_package_file() {
    npm_package_file="$npm_package_file_name"
    if [ -n "$git_top_level" ]; then
      git_top_level=$(sed 's/\([A-Za-z]\):/\/\L\1/' <<< "${git_top_level}")
      npm_package_file="${git_top_level}/${npm_package_file}"
    fi
    if [ ! -f "$npm_package_file" ]; then
      npm_package_file=""
      return 1
    fi
  }

  find_npm_name() {
    if [[ -n "$npm_package_file" ]]; then
      npm_name=$(awk -F '"' '/name/ {print $4}' $npm_package_file)
    fi
  }

  find_npm_version() {
    if [[ -n "$npm_package_file" ]]; then
      npm_version=$(awk -F '"' '/version/ {print $4}' $npm_package_file)
    fi
  }

  local color
  local npm_info

  find_git_top_level && find_npm_package_file && find_npm_name && find_npm_version

  # not in NPM package
  [[ -z "$npm_package_file" ]] && return

  npm_info="${npm_name}@${npm_version}"
  color=${NPM_PROMPT_COLOR}

  [[ "$npm_info" != "@" ]] && echo "${npm_info}${PADDING}|${color}"
}

function __powerline_scm_prompt {
  git_local_branch=""
  git_branch=""
  git_dirty=""
  git_dirty_count=""
  git_ahead_count=""
  git_ahead=""
  git_behind_count=""
  git_behind=""

  find_git_branch() {
    # Based on: http://stackoverflow.com/a/13003854/170413
    git_local_branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)

    if [[ -n "$git_local_branch" ]]; then
      if [[ "$git_local_branch" == "HEAD" ]]; then
        # Branc detached Could show the hash here
        git_branch=$(git rev-parse --short HEAD 2>/dev/null)
      else
        git_branch=$git_local_branch
      fi
    else
      git_branch=""
      return 1
    fi
  }

  find_git_dirty() {
    # All dirty files (modified and untracked)
    local status_count=$(git status --porcelain 2> /dev/null | wc -l)

    if [[ "$status_count" != 0 ]]; then
      git_dirty=true
      git_dirty_count="$status_count"
    else
      git_dirty=''
      git_dirty_count=''
    fi
  }

  find_git_ahead_behind() {
    if [[ -n "$git_local_branch" ]] && [[ "$git_branch" != "HEAD" ]]; then
      local upstream_branch=$(git rev-parse --abbrev-ref "@{upstream}" 2> /dev/null)
      # If we get back what we put in, then that means the upstream branch was not found.  (This was observed on git 1.7.10.4 on Ubuntu)
      [[ "$upstream_branch" = "@{upstream}" ]] && upstream_branch=''
      # If the branch is not tracking a specific remote branch, then assume we are tracking origin/[this_branch_name]
      [[ -z "$upstream_branch" ]] && upstream_branch="origin/$git_local_branch"
      if [[ -n "$upstream_branch" ]]; then
        git_ahead_count=$(git rev-list --left-right ${git_local_branch}...${upstream_branch} 2> /dev/null | grep -c '^<')
        git_behind_count=$(git rev-list --left-right ${git_local_branch}...${upstream_branch} 2> /dev/null | grep -c '^>')
        if [[ "$git_ahead_count" = 0 ]]; then
          git_ahead_count=''
        else
          git_ahead=true
        fi
        if [[ "$git_behind_count" = 0 ]]; then
          git_behind_count=''
        else
          git_behind=true
        fi
      fi
    fi
  }


  local color
  local scm_info

  find_git_branch && find_git_dirty && find_git_ahead_behind

  #not in Git repo
  [[ -z "$git_branch" ]] && return

  scm_info="${SCM_GIT_CHAR}${git_branch}"
  [[ -n "$git_dirty" ]] && color=${SCM_PROMPT_DIRTY_COLOR} || color=${SCM_PROMPT_CLEAN_COLOR}
  [[ -n "$git_behind" ]] && scm_info+="${SCM_PROMPT_BEHIND}${git_behind_count}"
  [[ -n "$git_ahead" ]] && scm_info+="${SCM_PROMPT_AHEAD}${git_ahead_count}"

  [[ -n "${scm_info}" ]] && echo "${scm_info}${PADDING}|${color}"
}

function __powerline_left_segment {
  local OLD_IFS="${IFS}"; IFS="|"
  local params=( $1 )
  IFS="${OLD_IFS}"
  local separator_char="${POWERLINE_LEFT_SEPARATOR}"
  local separator=""
  local styles=( ${params[1]} )

  if [[ "${SEGMENTS_AT_LEFT}" -gt 0 ]]; then
    styles[1]=${LAST_SEGMENT_COLOR}
    styles[2]=""
    separator="$(__color ${styles[@]})${separator_char}"
  fi

  styles=( ${params[1]} )
  LEFT_PROMPT+="${separator}$(__color ${styles[@]})${params[0]}"

  #Save last background for next segment
  LAST_SEGMENT_COLOR=${styles[0]}
  (( SEGMENTS_AT_LEFT += 1 ))
}

function __powerline_last_status_prompt {
  local symbols=()
  local stopped_jobs
  read -N1 stopped_jobs < <(jobs -sp)
  [[ $last_status -ne 0 ]] && symbols+="$(__color ${STATUS_PROMPT_ERROR_COLOR})${STATUS_PROMPT_ERROR}"
  [[ $UID -eq 0 ]] && symbols+="$(__color ${STATUS_PROMPT_ROOT_COLOR})${STATUS_PROMPT_ROOT}"
  [[ ! -z "$stopped_jobs" ]] && symbols+="$(__color ${STATUS_PROMPT_JOBS_COLOR})${STATUS_PROMPT_JOBS}"

  [[ -n "$symbols" ]] && echo "$symbols|${STATUS_PROMPT_COLOR}"
}

function __powerline_prompt_command {
  local last_status="$?" ## always the first
  local separator_char="${POWERLINE_PROMPT_CHAR}"

  [[ "$MULTILINE" == "YES" ]] && separator_char="${POWERLINE_LEFT_SEPARATOR}"

  LEFT_PROMPT=""
  SEGMENTS_AT_LEFT=0
  LAST_SEGMENT_COLOR=""

  ## left prompt ##
  for segment in $POWERLINE_PROMPT; do
    local info="$(__powerline_${segment}_prompt)"
    [[ -n "${info}" ]] && __powerline_left_segment "${info}"
  done

  [[ -n "${LEFT_PROMPT}" ]] && LEFT_PROMPT+="$(__color - ${LAST_SEGMENT_COLOR})${separator_char}$(__color)"

  [[ "$MULTILINE" == "YES" ]] \
    && PS1="\n${LEFT_PROMPT}\n\$ " \
    || PS1="${LEFT_PROMPT} "

  ## cleanup ##
  unset LAST_SEGMENT_COLOR \
        LEFT_PROMPT \
        SEGMENTS_AT_LEFT
}

function safe_append_prompt_command {
    local prompt_re

    # Set OS dependent exact match regular expression
    if [[ ${OSTYPE} == darwin* ]]; then
      # macOS
      prompt_re="[[:<:]]${1}[[:>:]]"
    else
      # Linux, FreeBSD, etc.
      prompt_re="\<${1}\>"
    fi

    if [[ ${PROMPT_COMMAND} =~ ${prompt_re} ]]; then
      return
    elif [[ -z ${PROMPT_COMMAND} ]]; then
      PROMPT_COMMAND="${1}"
    else
      PROMPT_COMMAND="${1};${PROMPT_COMMAND}"
    fi
}

safe_append_prompt_command __powerline_prompt_command

__color_matrix() {
  local buffer

  declare -A colors=([0]=black [1]=red [2]=green [3]=yellow [4]=blue [5]=purple [6]=cyan [7]=white)
  declare -A mods=([0]='' [1]=B [4]=U [5]=k [7]=N)

  # Print foreground color names
  echo -ne "       "
  for fgi in "${!colors[@]}"; do
    local fg=`printf "%10s" "${colors[$fgi]}"`
    #print color names
    echo -ne "\e[m$fg "
  done
  echo

  # Print modificators
  echo -ne "       "
  for fgi in "${!colors[@]}"; do
    for modi in "${!mods[@]}"; do
      local mod=`printf "%1s" "${mods[$modi]}"`
      buffer="${buffer}$mod "
    done
    # echo -ne "\e[m "
    buffer="${buffer} "
  done
  echo -e "$buffer\e[m"
  buffer=""

  # Print color matrix
  for bgi in "${!colors[@]}"; do
    local bgn=$((bgi + 40))
    local bg=`printf "%6s" "${colors[$bgi]}"`

    #print color names
    echo -ne "\e[m$bg "

    for fgi in "${!colors[@]}"; do
      local fgn=$((fgi + 30))
      local fg=`printf "%7s" "${colors[$fgi]}"`

      for modi in "${!mods[@]}"; do
        buffer="${buffer}\e[${modi};${bgn};${fgn}m "
      done
      # echo -ne "\e[m "
      buffer="${buffer}\e[m "
    done
    echo -e "$buffer\e[m"
    buffer=""
  done
}

__character_map () {
  echo "powerline: ±●➦★⚡★ ✗✘✓✓✔✕✖✗← ↑ → ↓"
  echo "other: ☺☻👨⚙⚒⚠⌛"
}
