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

AVAILABLE_TOOLS=(make rake python ant mvn gradle git)

# Make
make_project_marker() { echo "Makefile"; }
make_clean_command()  { echo "-f $1 clean"; }

# Rake
rake_project_marker() { echo "Rakefile"; }
rake_clean_command()  { echo "-f $1 clean"; }

# Python distutils
python_project_marker() { echo "setup.py"; }
python_clean_command()  { echo "$1 clean"; }

# Ant
ant_project_marker() { echo "build.xml"; }
ant_clean_command()  { echo "-f $1 clean"; }

# Maven
mvn_project_marker() { echo "pom.xml"; }
mvn_clean_command()  { echo "-f $1 clean"; }

# Gradle
gradle_project_marker() { echo "build.gradle"; }
gradle_clean_command()  { echo "-b $1 clean"; }

# Git gc
git_project_marker() { echo ".git/"; }
git_clean_command()  { echo "--git-dir $1 gc"; }


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

# Set required bash options.
shopt -s globstar

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
debug " * dry run: $DRY_RUN"
debug " * log level: $LOG_LEVEL"
debug " * directory: $DIRECTORY"
debug " * tools: ${TOOLS[@]}"

# Perform cleaning.
trap "exit" INT TERM EXIT
for tool in ${TOOLS[@]}; do
  if ! type $tool &> /dev/null; then
    warn "Warning: $tool does not seem to be available in PATH, skipping $tool projects cleaning."
  elif ! type ${tool}_project_marker &> /dev/null || ! type ${tool}_clean_command &> /dev/null; then
    warn "Warning: $tool is not supported, skipping."
  else
    info "Looking for $tool projects..."
    for marker in $DIRECTORY/**/`${tool}_project_marker`; do
      if [[ -e $marker ]]; then
        if type ${tool}_keep_project &> /dev/null && ! ${tool}_keep_project $marker &> /dev/null; then
          debug "Skipping project `dirname $marker`."
        else
          clean_command="$tool `${tool}_clean_command $marker`"
          if $DRY_RUN; then
            info $clean_command
          else
            info "Cleaning $tool project `dirname $marker`... "
            is_log_level 2 && eval $clean_command || eval $clean_command &> /dev/null
          fi
        fi
      fi
    done
  fi
done

# vim:set ts=2 sw=2 et:
