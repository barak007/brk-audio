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
versions=('1.5.0' '1.3.0' '1.4.0' '1.4.0' '1.3.0' '1.2.2' '1.1.0' '1.0.1')
slugs=('sub-lattice' 'autoloop' 'feedline' 'good-kick' 'rampa' 'zero-clip' 'sonoscopeia' 'hatch')
urls=('https://github.com/barak007/brk-audio/releases/download/sub-lattice-v1.5.0/install.sh' 'https://github.com/barak007/brk-audio/releases/download/autoloop-v1.3.0/install.sh' 'https://github.com/barak007/brk-audio/releases/download/feedline-v1.4.0/install.sh' 'https://github.com/barak007/brk-audio/releases/download/good-kick-v1.4.0/install.sh' 'https://github.com/barak007/brk-audio/releases/download/rampa-v1.3.0/install.sh' 'https://github.com/barak007/brk-audio/releases/download/zero-clip-v1.2.2/install.sh' 'https://github.com/barak007/brk-audio/releases/download/sonoscopeia-v1.1.0/install.sh' 'https://github.com/barak007/brk-audio/releases/download/hatch-v1.0.1/install.sh')
checksums=('516c8450d2219cdf34d7df7f62f0e59b795d79facbd325cf0344e315c2589793' '0e864515939440beb19e077b3efdb859cbfcd17e88b414bb298b9a47f2edd32d' '8c0acb99da2cec510efab10a57b3832237f6a32e215f273ae69847652bad7ea5' 'f436b9bd6468cfcd3c8956f8797c715f8ac531c9ead102c45dcca0b155674886' '5f91fc9f7791cad78ffc4b19ecab06f060fec0b6e28c86979940cb147c2b1b33' '8f33f30ce36660536e5ddf6d70b8703032fdc34898c1168162a35eaef88e63c2' 'aa81e238d3e35d6313b9ee50ddde76c9a4beb4b20f8950512a5d49b66c29a259' 'b3f09d790c8c434e7b02cc74175ad0438edc9fed78481dddab0fcf47ebf349bc')
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
