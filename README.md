# brk-audio

Releases of the Barakigal Audio plug-ins for macOS: Sub Lattice (synthesizer) and Autoloop (drum machine), as AU, VST3 and CLAP.

**Website: https://barak007.github.io/brk-audio/** (every plug-in, its versions, downloads and install commands)

This repository holds only the downloads and the website; the source code is not public.

## Install

Each release has an install command for Terminal, for example:

```sh
curl -fsSL https://github.com/barak007/brk-audio/releases/download/<plugin>-v<version>/install.sh | bash
```

It downloads that release, checks its checksum and copies the plug-in into `~/Library/Audio/Plug-Ins`. To install only some formats, name them: `... | bash -s -- vst3 clap` (any of `au`, `vst3`, `clap`). Or download the ZIP from the [releases](https://github.com/barak007/brk-audio/releases) and follow `INSTALL.txt` inside it.

The builds are not notarized by Apple yet.
