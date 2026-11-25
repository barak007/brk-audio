#!/bin/bash
# Gear plugins — generated from published, free releases. No sudo; installs to your user plug-in folders.
# Default formats: AU, VST3 and CLAP. Examples: bash gear.sh clap   /   bash gear.sh --list
# Every child installer is downloaded and SHA-256 checked before any installer runs.
# Each child also checks its release archive and safely replaces its own bundles.
# Installation stops on error; plugins installed earlier in the collection remain installed.
set -euo pipefail

collection='Gear plugins'
plugin_count=3
names=('Gear Tube' 'Gear Comp' 'Gear Exciter')
versions=('0.1.3' '0.1.3' '0.1.3')
slugs=('gear-tube' 'gear-comp' 'gear-exciter')
urls=('https://github.com/barak007/brk-audio/releases/download/gear-tube-v0.1.3/install.sh' 'https://github.com/barak007/brk-audio/releases/download/gear-comp-v0.1.3/install.sh' 'https://github.com/barak007/brk-audio/releases/download/gear-exciter-v0.1.3/install.sh')
checksums=('bbaf9414fef63be448cedac9e0c11c369897f17edb3258514d5d30b8c059c7ed' 'e2876490dd1d165f70917fd8399a74c4ab7d01c92938dd4218f302d10f867092' '28f9d985940058af3f5e8a0b400c0e262fc47d1a86984a9f0a98ec67718b8067')
work=""

cleanup() { if [ -n "$work" ]; then rm -rf "$work"; fi; }
fail() { echo "$*" >&2; exit 1; }
usage() {
    echo "Usage: bash gear.sh [--list | --dry-run] [au] [vst3] [clap]"
    echo "Installs $collection. No formats specified: AU, VST3 and CLAP."
    echo "--list shows the pinned releases; --dry-run shows the plan without downloading or installing."
}
main() {
    local formats=() list_only=0 dry_run=0 argument index installed=0 script
    for argument in "$@"; do
        case "$argument" in
            au | vst3 | clap) formats+=("$argument") ;;
            --list) list_only=1 ;;
            --dry-run) dry_run=1 ;;
            -h | --help) usage; return 0 ;;
            *) usage >&2; fail "Unknown option or format: $argument" ;;
        esac
    done
    if [ ${#formats[@]} -eq 0 ]; then formats=(au vst3 clap); fi
    echo "$collection — $plugin_count plugins"
    for ((index=0; index<plugin_count; index++)); do
        printf '  %s %s\n' "${names[$index]}" "${versions[$index]}"
    done
    if [ "$list_only" -eq 1 ]; then return 0; fi
    if [ "$plugin_count" -eq 0 ]; then fail "This collection has no published installers yet."; fi
    echo "Formats: ${formats[*]}"
    echo "Destination: $HOME/Library/Audio/Plug-Ins"
    if [ "$dry_run" -eq 1 ]; then return 0; fi
    if [ "$(uname)" != "Darwin" ]; then fail "These plug-ins require macOS."; fi
    trap cleanup EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    work="$(mktemp -d)"
    for ((index=0; index<plugin_count; index++)); do
        script="$work/${slugs[$index]}.sh"
        echo "Checking installer for ${names[$index]}..."
        curl -fL --retry 2 --proto '=https' --tlsv1.2 "${urls[$index]}" -o "$script"
        printf '%s  %s\n' "${checksums[$index]}" "$script" | shasum -a 256 -c --quiet - ||
            fail "Installer checksum failed for ${names[$index]}; no plugin installers were run."
    done
    for ((index=0; index<plugin_count; index++)); do
        echo "Installing ${names[$index]} (${versions[$index]})..."
        if ! bash "$work/${slugs[$index]}.sh" "${formats[@]}"; then
            fail "Stopped at ${names[$index]}. $installed earlier plugins were installed; fix the error and run again."
        fi
        installed=$((installed + 1))
    done
    echo "$collection is installed. Restart your DAW or rescan plug-ins."
}

# Nothing executes until the complete file has arrived when piped from curl.
main "$@"
