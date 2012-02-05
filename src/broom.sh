#!/usr/bin/env bash
# broom - a disk cleaning utility for developers
# Copyright (c) 2011-2012 Julien Nicoulaud <julien.nicoulaud@gmail.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

VERSION=dev

# ----------------------------------------------------------------------
# Tools definitions
# ----------------------------------------------------------------------

AVAILABLE_TOOLS=(make rake python ant mvn gradle buildr sbt ninja git bundle)

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

# Buildr
buildr_project_marker() { echo "buildfile"; }

# SBT
sbt_project_marker() { echo "{*.sbt,project/**/*.scala}"; }
sbt_cwd()  { [[ $1 == *.sbt ]] && echo `dirname $1` || echo "${1%\/project\/*}"; }

# Ninja
ninja_project_marker() { echo "build.ninja"; }
ninja_clean_args()  { echo "-t clean"; }

# Git gc
git_project_marker() { echo ".git/"; }
git_clean_args()  { echo "gc"; }

# Bundler
bundle_project_marker() { echo "Gemfile"; }


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
   -q,--quiet)    Decrease verbosity level.
   -n,--dry-run)  Do not actually perform actions.
   -t,--tools)    Comma-separated list of tools to use.
                  Available tools are: ${AVAILABLE_TOOLS[@]}.
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
    echo "$@" >&2
  else
    [[ $LOG_LEVEL -ge $level ]] && echo $@
  fi
}
info() { log 0 $@; }
debug() { log 1 $@; }
error() { log -2 $@; }
warn() { log -1 $@; }
is_log_level() { [[ $LOG_LEVEL -ge $1 ]]; }

# Check for bash requirements.
[[ ! $BASH_VERSINFO -ge 4 ]] && {
  error "This script requires bash>=4, exiting."
  exit 1
}

# Check for getopt requirements.
getopt -h 2>&1 | grep -qe '-l' || {
  error "This script requires GNU implementation of getopt, exiting."
  exit 1
}

# Set required bash options.
shopt -s globstar extglob

# Initialize default execution parameters.
LOG_LEVEL=0
DRY_RUN=false
DIRECTORY=.
TOOLS=(${AVAILABLE_TOOLS[@]})

# Load user configuration file if any.
[[ -f $HOME/.broomrc ]] && {
  debug "Loading ~/.broomrc"
  . $HOME/.broomrc
}

# Parse and validate options.
set -- `getopt -un$0 -l "help,version,verbose,quiet,dry-run,tools:" -o "hvqnt:" -- "$@"` || usage
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)    usage; exit 0 ;;
    --version)    version; exit 0 ;;
    -v|--verbose) let LOG_LEVEL++ ;;
    -q|--quiet)   let LOG_LEVEL-- ;;
    -n|--dry-run) DRY_RUN=true ;;
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
debug " - log level: $LOG_LEVEL"
debug " - directory: $DIRECTORY"
debug " - tools: ${TOOLS[@]}"

# Perform cleaning.
trap "exit" INT TERM EXIT
for tool in ${TOOLS[@]}; do
  if ! type $tool &> /dev/null; then
    warn "Warning: $tool does not seem to be available in PATH, skipping $tool projects cleaning."
  elif ! type ${tool}_project_marker &> /dev/null; then
    warn "Warning: $tool is not supported, skipping."
  else
    info "Looking for $tool projects..."
    for marker in $(eval echo $DIRECTORY/**/`${tool}_project_marker`); do
      if [[ -e $marker ]]; then
        project_dir="`dirname $marker`"
        if type ${tool}_keep_project &> /dev/null && ! ${tool}_keep_project $marker &> /dev/null; then
          debug "Skipping project ${project_dir}."
        else
          cwd="${project_dir}"; type ${tool}_cwd &> /dev/null && cwd="`${tool}_cwd $marker`"
          clean_args="clean"; type ${tool}_clean_args &> /dev/null && clean_args="`${tool}_clean_args $marker`"
          clean_command="cd ${cwd} && ${tool} ${clean_args}"
          if $DRY_RUN; then
            info $clean_command
          else
            info "Cleaning $tool project `dirname $marker`... "
            is_log_level 2 && (eval $clean_command) || (eval $clean_command &> /dev/null)
          fi
        fi
      fi
    done
  fi
done

# vim:set ts=2 sw=2 et:
