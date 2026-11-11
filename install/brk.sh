#!/bin/bash
# BRK plugins — generated from published, free releases. No sudo; installs to your user plug-in folders.
# Default formats: AU, VST3 and CLAP. Examples: bash brk.sh clap   /   bash brk.sh --list
# Every child installer is downloaded and SHA-256 checked before any installer runs.
# Each child also checks its release archive and safely replaces its own bundles.
# Installation stops on error; plugins installed earlier in the collection remain installed.
set -euo pipefail

collection='BRK plugins'
plugin_count=8
names=('BRK - Sub Lattice' 'BRK - Autoloop' 'BRK - Feedline' 'BRK - Good Kick' 'BRK - Rampa' 'BRK - Zero Clip' 'BRK - Sonoscopeia' 'BRK - Hatch')
versions=('1.4.1' '1.2.1' '1.3.1' '1.3.1' '1.2.1' '1.2.1' '1.0.1' '1.0.1')
slugs=('sub-lattice' 'autoloop' 'feedline' 'good-kick' 'rampa' 'zero-clip' 'sonoscopeia' 'hatch')
urls=('https://github.com/barak007/brk-audio/releases/download/sub-lattice-v1.4.1/install.sh' 'https://github.com/barak007/brk-audio/releases/download/autoloop-v1.2.1/install.sh' 'https://github.com/barak007/brk-audio/releases/download/feedline-v1.3.1/install.sh' 'https://github.com/barak007/brk-audio/releases/download/good-kick-v1.3.1/install.sh' 'https://github.com/barak007/brk-audio/releases/download/rampa-v1.2.1/install.sh' 'https://github.com/barak007/brk-audio/releases/download/zero-clip-v1.2.1/install.sh' 'https://github.com/barak007/brk-audio/releases/download/sonoscopeia-v1.0.1/install.sh' 'https://github.com/barak007/brk-audio/releases/download/hatch-v1.0.1/install.sh')
checksums=('6f6d8f3813dd7517a88bf72357af420774ebad3becbd5062c0be893759c503b6' '188e4e5771755578568b2fddf4e9451325b8446692ab8c6abfe10d9cbada577c' 'd8fe621aacd431157a9dc55c19734d2ed5981d4f5548a68678ec646095171846' '3f467fd46f5748b107e6e57a42584107d2648cdceb2a60da1a84f312e6a7f51e' '0515e94d9b2fc0162db91afab61eed9724ae9c00550b66d309df25b511e0fbec' 'a866d978f1224ed3c78e99aed29473d510612040202d39e15376e7e72a761228' 'f69b9142dfea60e38608cd9c577ffb3d917ca6afebb90f050dd7ab6b190dffde' 'b3f09d790c8c434e7b02cc74175ad0438edc9fed78481dddab0fcf47ebf349bc')
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
