#!/usr/bin/env bash

shopt -s expand_aliases

os=${OSTYPE//[0-9.]/}
if [[ "$os" == linux-gnu ]]; then
  sed_opts="-r"
  find_opts="-regextype posix-extended"
else
  #OSX
  sed_opts="-E"
  find_opts=""
  alias find="find -E"
fi

platform=$1
flavor=${2:-oreo}
current_dir=$(pwd)
script_dir=$( cd "$(dirname "$0")" ; pwd -P )
ios_compile_no_arc_regexp=("CHDataStructures\/.*\.m$")

if [[ "$platform" == android ]]; then
  src_root="android"
  # replace path android/*/src/ -> src/
  target_regexp="s/android\/.*\/src\/(main|$flavor)\/java/src/"
  sources_regexp=".*\/src\/(main|$flavor)\/java\/.*\.java$"
elif [[ "$platform" == ios ]]; then
  src_root="ios"
  sources_regexp=".*BackgroundGeolocation\/.*\.[h,m]$"
else
  echo "Missing or wrong parameter. Must be either: ios or android"
  exit 1;
fi

src_dir=$( cd "$script_dir/../$src_root" ; pwd )

if [[ "$current_dir/$src_root" != "$src_dir" ]]; then
  echo "Must be run from root dir: sh ./scripts/gen_sources.sh platform"
  exit 1
fi

src_files=$(find $src_dir $find_opts -regex $sources_regexp | sed "s|$src_dir|$src_root|" | sort)

echo "<!-- Generated with gen_sources.sh @ $(date '+%Y-%m-%d %H:%M:%S') -->"
for f in $src_files; do
  attrs=()
  if [[ ! -z "$target_regexp" ]]; then
    target_dir=$(dirname "$f" | sed $sed_opts "$target_regexp")
    attrs+=("target-dir=\"$target_dir\" ")
  fi
  for i in ${ios_compile_no_arc_regexp[@]}; do
    if [[ "$f" =~ ${i} ]]; then
      attrs+=("compiler-flags=\"-fno-objc-arc\" ")
    fi
  done
  if [[ "$f" == *h ]]; then
    echo "<header-file src=\"$f\" "${attrs[*]}"/>"
  else
    echo "<source-file src=\"$f\" "${attrs[@]}"/>"
  fi
done
echo "<!-- End of generated sources -->"
