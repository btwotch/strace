#!/bin/sh -efu
# Copyright (c) 2018 Dmitry V. Levin <ldv@altlinux.org>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote products
#    derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

input=bpf_attr.h
output="${0%/*}"/bpf_attr.m4
exec > "$output"

cat <<EOF
dnl Generated by $0 from $input; do not edit.
AC_DEFUN([st_BPF_ATTR], [dnl
	AC_CHECK_MEMBERS(m4_normalize([
EOF

fetch_structs()
{
	local name="${1:-}"
	local name_re=
	[ -z "$name" ] ||
		name_re='\/\* '"$name"' \*\/ '

	sed -n '/^struct BPF_[^[:space:]]\+_struct '"$name_re"'{/,/^};/p' < "$input"
}

filter_entries()
{
	local name="${1:-}"
	local subtype=
	[ -z "$name" ] ||
		subtype=".$name"
	local search='^[[:space:]]\+[^][;]*[[:space:]]\([^][[:space:];]\+\)\(\[[^;]*\]\)\?;$'
	local replacement='\t\tunion bpf_attr'"$subtype"'.\1,'
	sed -n "s/$search/$replacement/p" |
		sort -u
}

# nameless structures in union bpf_attr
fetch_structs |
	filter_entries

# named structures in union bpf_attr
for name in $(sed -n 's/^struct BPF_[^[:space:]]\+_struct \/\* \([^[:space:]]\+\) \*\/ {.*/\1/p' < "$input"); do
	fetch_structs "$name" |
		filter_entries "$name"
done

cat <<'EOF'
		union bpf_attr.dummy
	]),,, [#include <linux/bpf.h>])
])
EOF