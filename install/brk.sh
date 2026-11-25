#!/bin/bash
# BRK plugins — generated from published, free releases. No sudo; installs to your user plug-in folders.
# Default formats: AU, VST3 and CLAP. Examples: bash brk.sh clap   /   bash brk.sh --list
# Every child installer is downloaded and SHA-256 checked before any installer runs.
# Each child also checks its release archive and safely replaces its own bundles.
# Installation stops on error; plugins installed earlier in the collection remain installed.
set -euo pipefail

collection='BRK plugins'
plugin_count=10
names=('BRK - Sub Lattice' 'BRK - Autoloop' 'BRK - Feedline' 'BRK - Good Kick' 'BRK - Rampa' 'BRK - Zero Clip' 'BRK - Sonoscopeia' 'BRK - Hatch' 'BRK - Palmas' 'BRK - Sinabank')
versions=('1.7.0' '1.3.1' '1.6.0' '1.4.1' '1.3.1' '1.3.0' '1.1.0' '1.2.0' '0.1.0' '0.1.0')
slugs=('sub-lattice' 'autoloop' 'feedline' 'good-kick' 'rampa' 'zero-clip' 'sonoscopeia' 'hatch' 'palmas' 'sinabank')
urls=('https://github.com/barak007/brk-audio/releases/download/sub-lattice-v1.7.0/install.sh' 'https://github.com/barak007/brk-audio/releases/download/autoloop-v1.3.1/install.sh' 'https://github.com/barak007/brk-audio/releases/download/feedline-v1.6.0/install.sh' 'https://github.com/barak007/brk-audio/releases/download/good-kick-v1.4.1/install.sh' 'https://github.com/barak007/brk-audio/releases/download/rampa-v1.3.1/install.sh' 'https://github.com/barak007/brk-audio/releases/download/zero-clip-v1.3.0/install.sh' 'https://github.com/barak007/brk-audio/releases/download/sonoscopeia-v1.1.0/install.sh' 'https://github.com/barak007/brk-audio/releases/download/hatch-v1.2.0/install.sh' 'https://github.com/barak007/brk-audio/releases/download/palmas-v0.1.0/install.sh' 'https://github.com/barak007/brk-audio/releases/download/sinabank-v0.1.0/install.sh')
checksums=('9e995c54e7d277417941f2771f5c23542d4742bcd9674890cba038a90e24c013' '3d0457f790f91eb82b530d57965654530c4a389f8023398183aaf311f561f899' 'ae9948a49c335b9b07a8d6e96e10a6167c61419cb883bfbaaafb1c0d70a2d9a6' 'b0447fba5c7036201728f49a4ccddf496ba39bb9bce4bff4c912b00676cf6260' '1a985126d0e2ef502c9825f636ebfc1bd1fa37be0b097667bc80a2b55a9f7c5b' 'b09ecd51b8c8973fac2e2fb1aa4cdb281a8312128601da6f9be721aa67c466db' 'aa81e238d3e35d6313b9ee50ddde76c9a4beb4b20f8950512a5d49b66c29a259' '6a8be75f263b46c12161b4432ae2464a138f32744e7317a89c9af284fdd32e7a' 'b0c0e20df3b5950782fe53e7f1ed943bf0e07a4547542ec4b96ba56849e00fb3' 'fdc679fc7e373ec4b42c10424e22ba8793336201c3ba30eb973e45990c0fbb9d')
work=""

cleanup() { if [ -n "$work" ]; then rm -rf "$work"; fi; }
fail() { echo "$*" >&2; exit 1; }
usage() {
    echo "Usage: bash brk.sh [--list | --dry-run] [au] [vst3] [clap]"
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
