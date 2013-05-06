#!/bin/bash

# check_export.sh
# Copyright (C) 2012 Denis Efremov
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

# $1 - linux kernel sources directory
# $2 - export definitions file

PR_COEFF=1

usage ()
{
   echo "$0 <i|e|n|s> <kernel dir> <output>"
   echo "i - __init"
   echo "e - __exit"
   echo "n - inline"
   echo "s - static"
   exit ${1:-0}
}

[[ -z "$1" || -n "$(echo $1 | tr -d 'iens')" ]] && usage 1
arg="$1"

[[ -z "$2" ]] && usage 1
kdir="$(readlink -m -q -n "$2")"
[[ ! -r "${kdir}/Kbuild" ]] && usage 1

[[ -z "$3" ]] && usage 1
results="$3"

declare -A lock

extracted="$(mktemp)"

declare -i processors_num=$(grep -F -e 'processor' < /proc/cpuinfo | wc -l)
declare -i threads_num=$(( $processors_num * ${PR_COEFF:-0} ))
[[ $threads_num -eq 0 ]] && threads_num=1

#init
lock_def="$(seq 1 $threads_num | xargs -I % sh -c "{ touch '${extracted}.%.'{lock,file}; echo -n '[\"${extracted}.%.lock\"]=\"${extracted}.%.file\" '; }")"
eval lock=($lock_def)

grep --include="*.[ch]"          \
   --exclude-dir='Documentation' \
   --exclude-dir='samples'       \
   --exclude-dir='scripts'       \
   --exclude-dir='tools'         \
   --null -F -lre 'EXPORT_SYMBOL' "$kdir" |
      xargs --null --max-lines=1 --max-procs=$threads_num --no-run-if-empty -I % bash -c \
      "{                                                          \
         declare -A lock=($lock_def);                             \
         for i in \${!lock[@]};                                   \
         do                                                       \
            (                                                     \
               flock --exclusive --nonblock 9 || exit 1;          \
               ./check_export.pl -${arg} < '%' >> \${lock[\$i]} && echo -n -e \"\$(readlink -e -n '%')\n\n\" >> \${lock[\$i]};         \
               if [[ \$? -eq 0 ]]; then exit 0; else exit 2; fi;  \
            ) 9>>\$i;                                             \
            if [[ \$? -eq 0 ]]; then break; fi;                   \
         done;                                                    \
      }"

cat "${lock[@]}" > "$results"

#exit
rm -f "${lock[@]}" "${!lock[@]}"
unset $( sed -e 's/[^ ]\+/lock[&]/g' <<< "${!lock[@]}" )
rm -f "$extracted"

