# Protocol

XDR protocol files and other common definitions that must be shared between languages.

![phil, PC: https://www.indystar.com/story/entertainment/2025/02/03/how-accurate-is-punxsutawney-phil-prognosticator-staten-island-chuck-mojave-max-lander-lil-noaa-rank/78188106007/](https://github.com/groundhogchain/phild/blob/main/phil.webp?raw=true)

# Usage

Include as a submodule in other repositories.

Format with `./scripts/format.sh`

The [text-encoding specification](docs/text-encoding.md) defines the target
base58/StrKey representations without changing binary serialization. Check its
public cross-language vectors with `python3 scripts/text_encoding_vectors.py`.
