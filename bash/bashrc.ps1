# bashrc.ps1 — enhanced PS1 with multi-line format, git branch, pyenv, and AWS profile

# --- Color Definitions ---
GREEN_COLOR='\[\033[01;32m\]'
BLUE_COLOR='\[\033[01;34m\]'
YELLOW_COLOR='\[\033[01;33m\]'
NO_COLOR='\[\033[00m\]'

# --- Smart Path Truncation ---
# Truncates long paths to /start/...penultimate/final format
smart_pwd() {
  local home_path="${PWD/#$HOME/~}"
  local IFS='/'
  read -ra parts <<<"$home_path"
  local len=${#parts[@]}

  if [ $len -gt 3 ]; then
    echo "${parts[0]}/.../${parts[-2]}/${parts[-1]}"
  else
    echo "$home_path"
  fi
}

# --- Git Branch Parsing ---
parse_git_branch() {
  git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/[\1]/'
}

# --- Pyenv Version Display ---
ps1_pyenv() {
  if command -v pyenv &>/dev/null && [ ! -z "$(pyenv version-name 2>/dev/null)" ]; then
    echo "PY:$(pyenv version-name)"
  fi
}

# --- Kubernetes Context Display ---
ps1_kube() {
  if command -v kube_ps1 &>/dev/null && [ ! -z "$(kube_ps1)" ]; then
    echo " $(kube_ps1)"
  fi
}

# --- AWS Profile Display ---
ps1_aws() {
  if [ -n "${AWS_PROFILE}" ]; then
    echo " [AWS:${AWS_PROFILE}]"
  fi
}

# --- Final PS1 (Multi-line) ---
# Format:
#   ┌─[user@host]─[path]
#   [git-branch] PY:version [AWS:profile]
#   └──╼ $
_build_ps1() {
  local _path _git _py _aws _kube
  _path=$(smart_pwd)
  _git=$(parse_git_branch)
  _py=$(ps1_pyenv)
  _aws=$(ps1_aws)
  [[ "$(uname -o 2>/dev/null)" != @(Cygwin|Msys) ]] && _kube=$(ps1_kube)
  PS1='\[\033[01;32m\]┌─[\[\033[00m\]\u@\h\[\033[01;32m\]]─[\[\033[01;34m\]'"${_path}"'\[\033[01;32m\]]\[\033[00m\]\n\[\033[01;33m\]'"${_git} ${_py}${_aws}${_kube}"'\[\033[00m\]\n\[\033[01;32m\]└──╼\[\033[00m\] \$ '
}
PROMPT_COMMAND=_build_ps1
