#compdef broom
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


_arguments \
  '(- 1 *)'{-h,--help}'[show usage message and exit]' \
  '(- 1 *)--version[show program version and exit]' \
  '*'{-v,--verbose}'[increase verbosity level]' \
  '*'{-q,--quiet}'[decrease verbosity level]' \
  {-n,--dry-run}'[do not actually perform actions]' \
  {-t,--tools}'[comma-separated list of tools to use]: :_values -s ',' tool make rake python ant mvn gradle buildr sbt ninja git bundle' \
  '*: :_files -/'

# vim: ft=zsh sw=2 ts=2 et
