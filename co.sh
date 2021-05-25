#!/bin/bash

FILE_EXT=".cmake$|.cpp$|.csv$|.h$|.md$|.py$|.pyx$|.sh$|.txt$|.yaml$|.yml$|.ipynb$"

function find_dir_owner() {
        local d="${1:-.}"; shift

        local df=$(echo ${d} | cut -c3-)

        nf=$(find ${d} -maxdepth 1 -mindepth 1 -type f -not -size 0 -not -path "*/\.*" | \
                     grep -E "$FILE_EXT" | \
                     wc -l
          )
        # If no files, then no assignment and return.
        if [ ${nf} -eq 0 ]; then
                echo "# ${df}"
                return
        fi
                
        echo -n "${df}/* "
        find ${d} -maxdepth 1 -mindepth 1 -type f -not -size 0 -not -path "*/\.*" | \
                `# take only file with specified extensions` \
                grep -E "$FILE_EXT" | \
                `# get blame for each line in machine mode` \
                xargs -I{} -exec git blame --show-email --line-porcelain {} | \
                `# get lines for authors` \
                sed -n 's/^author-mail //p' | \
                `# group lines and then sort based on the number of blamed lines` \
                sort | uniq -c | sort -rn | \
                `# remove leading spaces and numbers` \
                sed 's/^ *//g' | \
                cut -d' ' -f2- | head -n 1 |
                sed 's/<\(.*\)>/\1/g'
}

function find_owners_for_repo() {
        local repo="${1:-.}"

        ( cd ${repo}
          for d in $(find . -type d -not -path '*/\.*'); do
                  find_dir_owner "${d}"
          done
        )
}

# ----------
# Main

repo="${1:-}"
if [ "${repo}" == "" ]; then
        echo "ERROR: Provide path to the repository"
        exit 1
elif [ ! -d "${repo}" ]; then
        echo "ERROR: Repo does not exist"
        exit 2
fi

find_owners_for_repo "${repo}"
#find_dir_owner "."
