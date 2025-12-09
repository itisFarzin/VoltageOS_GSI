#!/bin/bash

set -e

source="$(readlink -f -- "$1")"
td="$source/patches/trebledroid"
personal="$source/patches/personal"

apply_patches() {
    local path_dir="$1"
    local label="${path_dir##*/}"
	label="${label^^}"

    if [ -e "$path_dir" ]; then
        printf "\n ##### APPLYING ${label} PATCHES #####\n"
        sleep 1.0

        for path in "$path_dir"/*; do
            name="$(basename "$path")"
            tree="$(tr _ / <<< "$name" | sed -e 's;platform/;;g')"
            printf "\n| $name #####\n"

            case "$tree" in
                build) tree=build/make ;;
                vendor/hardware/overlay) tree=vendor/hardware_overlay ;;
                treble/app) tree=treble_app ;;
                frameworks/base/new) tree=frameworks/base ;;
            esac

            if [[ "$label" == "TREBLEDROID" ]]; then
                repo sync -l --force-sync "$tree" || continue
            fi

            pushd "$tree"
            git clean -fdx
            git reset --hard

            for patch in "$path/"*.patch; do
                if patch -f -p1 --dry-run -R < "$patch" > /dev/null; then
                    printf "##### ALREADY APPLIED: $patch\n"
                    continue
                fi

                if git apply --check "$patch"; then
                    git am "$patch"
                elif patch -f -p1 --dry-run < "$patch" > /dev/null; then
                    git am "$patch" || true
                    patch -f -p1 < "$patch"
                    git add -u
                    git am --continue
                else
                    printf "##### FAILED TO APPLY: $patch\n"
                fi
            done
            popd
        done
    else
        printf "\n##### NO ${label} PATCHES #####\n"
    fi
}

apply_patches "$td"
apply_patches "$personal"
