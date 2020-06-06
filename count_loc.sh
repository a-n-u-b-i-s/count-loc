#!/bin/sh
# title           : count_loc (Count Lines of Code)
# description     : The script counts the lines of code in Git Repos at [scan_dir]
# date            : 05/17/2020
# version         : 1.0
# usage           : count_loc.sh [-p [scan_dir]] [-o] [-f] [-e | -m]
# notes           : [scan_dir] must be a directory cotaining Git Repos
# bash_version    : GNU bash, version 3.2.57(1)-release (x86_64-apple-darwin19)
#============================================================================== 
set -e
# alias grep="ggrep"
#====================================
# Prints out Error Message
# Arguments:
#   Error Message.
#====================================
err() {
  echo "$*" >&2
  exit 1
}

#====================================
# Prints out Usage Error Message
# Arguments:
#   None.
#====================================
usage_err() {
  err "Usage: count_loc.sh [-p [scan_dir]] [-o] [-f] [-e | -m]"
}

#====================================
# Parse Options
#====================================
scan_dir=''                    # -p
omit_blank_lines=false         # -o
file_level_line_counts=false   # -f
filter_extensions=false        # -e
extensions_map=false           # -m

while getopts 'p:bfemsv' arg; do
  case "${arg}" in
    p) scan_dir="${OPTARG}"          ;;
    o) omit_blank_lines=true         ;;
    f) file_level_line_counts=true   ;;
    e) filter_extensions=true        ;;
    m) extensions_map=true           ;;
    *) usage_err                     ;;
  esac
done

#====================================
# Validate Options
#====================================
if [[ "$scan_dir" == "" ]]; then
  scan_dir="."
fi
if ! [[ -d $scan_dir ]]; then
  err 'Error: [scan_dir] must be a directory'
fi

if [[ $filter_extensions == true || \
      $extensions_map == true || ]]; then
  if grep -cqP "^truetrue$" \
    <<< "$filter_extensions$extensions_map"; then
    usage_err
  fi
fi

#====================================
# Keep Track of Current Dir
#====================================
current_dir=$(pwd)

#====================================
# Sends output to stdout and file
# Arguments:
#   Output Message.
#====================================
write_output_repo_level() {
  echo "$*" >&1
  echo "$*" >> $currentDir/lines_per_repo.csv
}

write_output_file_level() {
  echo "$*" >&1
  echo "$*" >> $currentDir/lines_per_file.csv
}

git config --global core.autocrlf false # This was added to surpress CRLF warnings in Windows

# Filter by file_extensions.txt
if [[ $filter_extensions == true ]]; then
  
  if ! [[ -f "$current_dir/file_extensions.txt" ]]; then
    err "file_extensions.txt is missing"
  fi

  extensions=''
  while read ext; do
    extensions+="*.${ext} ";
  done < "$current_dir/file_extensions.txt"
  
  find $scan_dir -type d -maxdepth 1 -exec test -e '{}/.git' ';' -print -prune \
  | while read line; do
    cd "$line"
    repo_line_count=''
    if [[ $omit_blank_lines == true ]]; then
      repo_line_count="$(git diff `git hash-object -t tree /dev/null` $extensions \
          | grep -oP '(^\+[^\+]+\s*.*\S+.*$)' \
          | wc -l)"
      if [[ $file_level_line_counts == true ]]; then
        git ls-files $extensions \
        | while read file_name; do
          file_line_count="$(git diff `git hash-object -t tree /dev/null` $file_name \
          | grep -oP '(^\+[^\+]+\s*.*\S+.*$)' \
          | wc -l)"
          file_line_count="$(echo $file_line_count | grep -oP '\d*')"
          write_output_file_level "$(pwd),$file_name,${file_line_count}" # Ouput Line Count
        done
      fi
    else
      repo_line_count="$(git diff `git hash-object -t tree /dev/null` $extensions \
          | grep -oP '(^\+[^\+]+\s*.*\S+.*$|^\+$)' \
          | wc -l)"
      if [[ $file_level_line_counts == true ]]; then
        git ls-files $extensions \
        | while read file_name; do
          file_line_count="$(git diff `git hash-object -t tree /dev/null` $file_name \
          | grep -oP '(^\+[^\+]+\s*.*\S+.*$|^\+$)' \
          | wc -l)"
          file_line_count="$(echo $file_line_count | grep -oP '\d*')"
          write_output_file_level "$(pwd),$file_name,${file_line_count}" # Ouput Line Count
        done
      fi
    fi
    repo_line_count="$(echo $repo_line_count | grep -oP '\d*')"
    write_output_repo_level "$(pwd),${repo_line_count}"
    cd "$current_dir"
  done
# Filter by file_extensions_map.txt
elif [[ $extensions_map == true ]]; then
  # echo "Filtering files based on file_extensions_map.txt..."
  # if ! [[ -f "$current_dir/file_extensions_map.txt" ]]; then
  #   err "file_extensions_map.txt is missing"
  # fi
  while read info; do
    repo_data=($(echo $info | tr ":" "\n"))
    repo_path=$repo_data[0]
    repo_extensions=$repo_data[1]
    extensions_text=$(echo $repo_extensions | tr "," "\n")
    extensions=''
    for ext in "${extensions_text}"; do
      extensions+="*.${ext} ";
    done
    cd "$scan_path/$repo_path"
    repo_line_count=''
    if [[ $omit_blank_lines == true ]]; then
      repo_line_count="$(git diff `git hash-object -t tree /dev/null` $extensions \
          | grep -oP '(^\+[^\+]+\s*.*\S+.*$)' \
          | wc -l)"
      if [[ $file_level_line_counts == true ]]; then
        git ls-files $extensions \
        | while read file_name; do
          file_line_count="$(git diff `git hash-object -t tree /dev/null` $file_name \
          | grep -oP '(^\+[^\+]+\s*.*\S+.*$)' \
          | wc -l)"
          file_line_count="$(echo $file_line_count | grep -oP '\d*')"
          write_output_file_level "$(pwd),$file_name,${file_line_count}" # Ouput Line Count
        done
      fi
    else
      repo_line_count="$(git diff `git hash-object -t tree /dev/null` $extensions \
          | grep -oP '(^\+[^\+]+\s*.*\S+.*$|^\+$)' \
          | wc -l)"
      if [[ $file_level_line_counts == true ]]; then
        git ls-files $extensions \
        | while read file_name; do
          file_line_count="$(git diff `git hash-object -t tree /dev/null` $file_name \
          | grep -oP '(^\+[^\+]+\s*.*\S+.*$|^\+$)' \
          | wc -l)"
          file_line_count="$(echo $file_line_count | grep -oP '\d*')"
          write_output_file_level "$(pwd),$file_name,${file_line_count}" # Ouput Line Count
        done
      fi
    fi
    repo_line_count="$(echo $repo_line_count | grep -oP '\d*')"
    write_output_repo_level "$(pwd),${repo_line_count}"
    cd "$current_dir"
  done < "$current_dir/file_extensions_map.txt"
else
  # echo "All files in all repos will be scanned..."
  find $scan_dir -type d -maxdepth 1 -exec test -e '{}/.git' ';' -print -prune \
  | while read line; do
      cd "$line" # Switch to Github Repo
      repo_line_count=''
      if [[ $omit_blank_lines == true ]]; then
          repo_line_count="$(git diff `git hash-object -t tree /dev/null` \
          | grep -oP '(^\+[^\+]+\s*.*\S+.*$)' \
          | wc -l)"
          if [[ $file_level_line_counts == true ]]; then
            git ls-files \
            | while read file_name; do
              file_line_count="$(git diff `git hash-object -t tree /dev/null` $file_name \
              | grep -oP '(^\+[^\+]+\s*.*\S+.*$)' \
              | wc -l)"
              file_line_count="$(echo $file_line_count | grep -oP '\d*')"
              write_output_file_level "$(pwd),$file_name,${file_line_count}" # Ouput Line Count
            done
          fi
      else
          repo_line_count="$(git diff `git hash-object -t tree /dev/null` \
          | grep -oP '(^\+[^\+]+\s*.*\S+.*$|^\+$)' \
          | wc -l)"
          if [[ $file_level_line_counts == true ]]; then
            git ls-files \
            | while read file_name; do
              file_line_count="$(git diff `git hash-object -t tree /dev/null` $file_name \
              | grep -oP '(^\+[^\+]+\s*.*\S+.*$|^\+$)' \
              | wc -l)"
              file_line_count="$(echo $file_line_count | grep -oP '\d*')"
              write_output_file_level "$(pwd),$file_name,${file_line_count}" # Ouput Line Count
            done
          fi
      fi
      repo_line_count="$(echo $repo_line_count | grep -oP '\d*')"
      write_output_repo_level "$(pwd),${repo_line_count}" # Ouput Line Count
      cd "$currentDir" # Switch to Main Dir
    done
fi