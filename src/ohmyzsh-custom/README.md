
# Oh My Zsh Customization (ohmyzsh-custom)

Set up and configure common Oh My Zsh plugins and theme(s)

## Example Usage

```json
"features": {
    "ghcr.io/clusterhack/devcontainer-features/ohmyzsh-custom:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| plugins | Space-separated list of plugins to install and enable; see documentation for supported plugins. | string | git virtualenv zsh-autosuggestions per-directory-history |
| theme | Theme to select, installing if necessary | string | p10k |
| disableAutoupdate | Disable Oh My Zsh auto-update check | boolean | true |
| installAliases | Install alias presets | boolean | true |
| extraAliases | File with extra alias definitions; relative to repo root | string | - |
| extraPowerlevel10kCustomizations | File with extra Powerlevel10k customizations; relative to repo root | string | - |
| extraAgnosterCustomizations | File with extra Agnoster customizations; relative to repo root | string | - |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/clusterhack/devcontainer-features/blob/main/src/ohmyzsh-custom/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
