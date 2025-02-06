#!/bin/bash

# Check if any arguments were provided
if [ "$#" -eq 0 ]; then
  echo "Usage: $0 file1 [file2 ...]" >&2
  echo "Provide filenames or globs. For recursive matching, use **/ and enable 'shopt -s globstar'." >&2
  exit 1
fi

{
  for file in "$@"; do
    if [ ! -f "$file" ]; then
      echo "Error: '$file' is not a file or doesn't exist." >&2
      continue
    fi
    echo "$file    ###"
    mime=$(file --mime-type -b "$file")
    echo '```'"$mime"
    cat "$file"
    echo '```'
  done
} | xclip -selection clipboard
