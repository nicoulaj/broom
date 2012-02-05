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


_broom()
{
  cur=${COMP_WORDS[COMP_CWORD]}
  if [ $COMP_CWORD -eq 1 ]; then
    COMPREPLY=( $( compgen -W "-h --help --version -v --verbose -q --quiet -n --dry-run -t --tools" -- $cur ) )
  else
    first=${COMP_WORDS[1]}
    case "$first" in
      --version|-h|--help)
        COMPREPLY=()
        ;;
      *)
        prev=${COMP_WORDS[COMP_CWORD-1]}
        case "$prev" in
          -t|--tools)
            COMPREPLY=( $(compgen -W "make rake python ant mvn gradle buildr sbt ninja git bundle" $cur) )
            ;;
          *)
            COMPREPLY=( $(compgen -W "-v --verbose -q --quiet -n --dry-run -t --tools" -- $cur ) )
            ;;
        esac
        ;;
    esac
  fi
}

complete -F _broom -o dirnames broom
