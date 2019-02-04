#!/usr/bin/env bash
# broom - a disk cleaning utility for developers
# Copyright (c) 2011-2018 Julien Nicoulaud <julien.nicoulaud@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

VERSION=dev

# ----------------------------------------------------------------------
# Tools definitions
# ----------------------------------------------------------------------

AVAILABLE_TOOLS=(make rake python ant mvn gradle buildr sbt ninja scons waf rant git bundle vagrant makepkg cargo)

# Make
make_project_marker() { echo "Makefile"; }

# Rake
rake_project_marker() { echo "Rakefile"; }

# Python distutils
python_project_marker() { echo "setup.py"; }
python_clean_args()  { echo "$1 clean"; }

# Ant
ant_project_marker() { echo "build.xml"; }

# Maven
mvn_project_marker() { echo "pom.xml"; }
mvn_keep_project()   { [[ -f $(dirname `dirname $1`)/pom.xml ]] && return 1 || return 0; }

# Gradle
gradle_project_marker() { echo "build.gradle"; }
gradle_clean_args()  { echo "--daemon clean"; }

# Buildr
buildr_project_marker() { echo "buildfile"; }

# SBT
sbt_project_marker() { echo "{*.sbt,project/**/*.scala}"; }
sbt_cwd()  { [[ $1 == *.sbt ]] && echo `dirname $1` || echo "${1%\/project\/*}"; }

# Ninja
ninja_project_marker() { echo "build.ninja"; }
ninja_clean_args()  { echo "-t clean"; }

# SCons
scons_project_marker() { echo "SConstruct"; }
scons_clean_args()  { echo "-c"; }

# Waf
waf_project_marker() { echo "wscript"; }

# Rant
rant_project_marker() { echo "Rantfile"; }

# Git gc
git_project_marker() { echo ".git/"; }
git_clean_args()  { echo "gc"; }

# Bundler
bundle_project_marker() { echo "Gemfile"; }

# Vagrant
vagrant_project_marker() { echo "Vagrantfile"; }
vagrant_clean_args() { echo "destroy -f"; }
vagrant_needs_confirmation() { :; }

# Makepkg
makepkg_project_marker() { echo "PKGBUILD"; }
makepkg_clean_args() { echo "-cdeof"; }

# Rust
cargo_project_marker() { echo "Cargo.toml"; }


# ----------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------

# Define usage function.
usage() {
  cat << EOF
usage: $0 [option...] [directory]

A disk cleaning utility for developers.

OPTIONS:
  -h,--help      Show this message and exit.
  --version      Show version number and exit.
  -v,--verbose   Increase verbosity level.
  -q,--quiet     Decrease verbosity level.
  -n,--dry-run   Do not actually perform actions.
  --noconfirm    Do not ask for confirmation before performing actions
                 that may result in potential data loss (eg: destroying
                 Vagrant boxes).
  -s,--stats     Show space gained.
  -t,--tools     Comma-separated list of tools to use.
                 Available tools are: ${AVAILABLE_TOOLS[@]}.
                 By default, all tools are used.
EOF
}

# Define version function.
version() {
  cat << EOF
$0 $VERSION
EOF
}

# Define logging functions.
log() {
  level=$1; shift
  if [[ $level -lt 0 ]]; then
    if [[ $level -lt -1 ]]; then
      echo "$(tput setaf 1)$(tput bold)$@$(tput sgr0)" >&2
    else
      echo "$(tput setaf 3)$(tput bold)$@$(tput sgr0)" >&2
    fi
  elif [[ $LOG_LEVEL -ge $level ]]; then
    if [[ $level -ge 1 ]]; then
      echo "$(tput dim)$@$(tput sgr0)"
    else
      echo "$@"
    fi
  fi
}
error() { log -2 "$@"; }
warn() { log -1 "$@"; }
info() { log 0 "$@"; }
debug() { log 1 "$@"; }
trace() { log 2 "$@"; }
is_log_level() { [[ $LOG_LEVEL -ge $1 ]]; }

# Check for bash requirements.
[[ ! $BASH_VERSINFO -ge 4 ]] && {
  error "This script requires bash>=4, exiting."
  exit 1
}

# Check for getopt requirements.
if getopt -h 2>&1 | grep -qe '-l'; then
  GETOPT=getopt
elif /compat/linux/bin/getopt -h 2>&1 | grep -qe '-l'; then
  GETOPT=/compat/linux/bin/getopt
else
  error "This script requires GNU implementation of getopt, exiting."
  exit 1
fi

# Set required bash options.
shopt -s globstar extglob

# Initialize default execution parameters.
LOG_LEVEL=0
DRY_RUN=false
STATS=false
CONFIRM_DESTRUCTIVE_ACTION=true
DIRECTORY=.
TOOLS=(${AVAILABLE_TOOLS[@]})

# Load user configuration file if any.
[[ -f $HOME/.broomrc ]] && {
  debug "Loading ~/.broomrc"
  . $HOME/.broomrc
}

# Parse and validate options.
set -- `$GETOPT -un$0 -l "help,version,verbose,quiet,dry-run,stats,noconfirm,tools:" -o "hvqnst:" -- "$@"` || usage
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)    usage; exit 0 ;;
    --version)    version; exit 0 ;;
    -v|--verbose) let LOG_LEVEL++ ;;
    -q|--quiet)   let LOG_LEVEL-- ;;
    -n|--dry-run) DRY_RUN=true ;;
    -s|--stats)   STATS=true ;;
    --noconfirm)  CONFIRM_DESTRUCTIVE_ACTION=false ;;
    -t|--tools)   TOOLS=(${2//,/ }); shift ;;
    --)           shift; break ;;
    -*)           usage; exit 1 ;;
    *)            break ;;
  esac
  shift
done

# Parse and validate arguments.
[[ $# -gt 1 ]] && {
  error "Error: too many arguments, exiting."
  usage
  exit 1
}
[[ -n $1 ]] && DIRECTORY=$1
[[ ! -d $DIRECTORY ]] && {
  error "Error: could not find directory $DIRECTORY, exiting."
  usage
  exit 1
}

# Debug logging.
debug "Running with parameters:"
debug " - dry run: $DRY_RUN"
debug " - stats: $STATS"
debug " - confirm actions resulting in potential data loss: $CONFIRM_DESTRUCTIVE_ACTION"
debug " - log level: $LOG_LEVEL"
debug " - directory: $DIRECTORY"
debug " - tools: ${TOOLS[@]}"

# Perform cleaning.
trap "exit" INT TERM EXIT
$STATS && gained=0
for tool in ${TOOLS[@]}; do
  if ! type $tool &> /dev/null; then
    warn "Warning: $tool does not seem to be available in PATH, skipping $tool projects cleaning."
  elif ! type ${tool}_project_marker &> /dev/null; then
    warn "Warning: $tool is not supported, skipping."
  else
    debug "Looking for $tool projects..."
    for marker in $(eval echo $DIRECTORY/**/`${tool}_project_marker`); do
      if [[ -e $marker ]]; then
        cwd="`dirname $marker`"; type ${tool}_cwd &> /dev/null && cwd="`${tool}_cwd $marker`"
        clean_args="clean"; type ${tool}_clean_args &> /dev/null && clean_args="`${tool}_clean_args $marker`"
        clean_command="cd ${cwd} && ${tool} ${clean_args}"
        info -n "${clean_command}"
        if $DRY_RUN || (type ${tool}_keep_project &> /dev/null && ! ${tool}_keep_project $marker &> /dev/null); then
          info " $(tput setaf 4)[SKIPPED]$(tput sgr0)"
        else
          doit=false
          if $CONFIRM_DESTRUCTIVE_ACTION && type ${tool}_needs_confirmation &> /dev/null; then
            read -p " ? [y/n] " -n 1 -r
            [[ $REPLY =~ ^[Yy]$ ]] && doit=true || info " $(tput setaf 4)[SKIPPED]$(tput sgr0)"
          else
            doit=true
          fi
          if $doit; then
            $STATS && before=($(du -bs "${cwd}")) && before=${before[0]}
            if is_log_level 2; then
              info
              while read; do
                trace "  [${tool}] ${REPLY}"
              done < <(eval $clean_command 2>&1)
            else
              (eval $clean_command &> /dev/null)
              (( $? == 0 )) && info " $(tput setaf 2)[OK]$(tput sgr0)" || info " $(tput setaf 1)[FAIL]$(tput sgr0)"
            fi
            $STATS && after=($(du -bs "${cwd}")) && after=${after[0]} && gained=$(( gained + before - after ))
          fi
        fi
      fi
    done
  fi
done
if $STATS; then
  if hash numfmt 2>/dev/null; then
    info "$(numfmt --to=iec --suffix=B ${gained}) gained"
  else
    info "${gained} bytes gained"
  fi
fi

# vim:set ts=2 sw=2 et:
