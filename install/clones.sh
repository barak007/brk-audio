#!/bin/bash
# Digital clones — generated from published, free releases. No sudo; installs to your user plug-in folders.
# Default formats: AU, VST3 and CLAP. Examples: bash clones.sh clap   /   bash clones.sh --list
# Every child installer is downloaded and SHA-256 checked before any installer runs.
# Each child also checks its release archive and safely replaces its own bundles.
# Installation stops on error; plugins installed earlier in the collection remain installed.
set -euo pipefail

collection='Digital clones'
plugin_count=2
names=('BRK - Tine 73' 'BRK 3-03')
versions=('0.5.1' '0.2.1')
slugs=('tine73' 'brk-303')
urls=('https://github.com/barak007/brk-audio/releases/download/tine73-v0.5.1/install.sh' 'https://github.com/barak007/brk-audio/releases/download/brk-303-v0.2.1/install.sh')
checksums=('948c5f177c95b7a913ce59a92b0880b9482024df9d96b8921f0a110da83a41ad' 'e55cdb87a63084634a3d18a795d2ddc4012a7a121349236b949df2ec04b4fe7c')
work=""

cleanup() { if [ -n "$work" ]; then rm -rf "$work"; fi; }
fail() { echo "$*" >&2; exit 1; }
usage() {
    echo "Usage: bash clones.sh [--list | --dry-run] [au] [vst3] [clap]"
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
