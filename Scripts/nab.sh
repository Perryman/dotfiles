#!/bin/bash

# Check if any arguments were provided
if [ "$#" -eq 0 ]; then
  echo "Usage: $0 file1 [file2 ...]" >&2
  echo "Provide filenames or globs. For recursive matching, use **/ and enable 'shopt -s globstar'." >&2
  exit 1
fi

# Check if xclip is installed
if ! command -v xclip &> /dev/null; then
  echo "Error: xclip is not installed. Please install it to use this script." >&2
  exit 1
fi

{
  declare -A seen_files
  for file in "$@"; do
    if [ -n "${seen_files["$file"]}" ]; then
      continue
    fi
    if [ ! -f "$file" ]; then
      echo "Error: '$file' is not a file or doesn't exist." >&2
      continue
    fi
    seen_files["$file"]=1
    echo "#####  $file  #####"
    mime=$(file --mime-type -b "$file")
    echo '```'"$mime"
    cat "$file"
    echo '```'
  done
} | xclip -selection clipboard
