# popup

> **WARNING: This software is under active development and is unstable.**

A toolchain manager for Pop Language. Downloads, installs, and manages Pop compiler and runtime distributions.

`popup` handles toolchain distribution independently from `pop`, the language and package command. It behaves like `rustup`: one manager, many installed toolchains, one selected default. Pop toolchains come from the [Pop Index](https://pop.squareweb.app/); Popup itself is bootstrapped from its verified GitHub Release.

## Installation

### Build from source

```sh
git clone git@github.com:poplanguage/popup
cd popup
shards install
shards build
```

### macOS and Linux

```sh
curl -fsSL https://raw.githubusercontent.com/poplanguage/popup/master/scripts/bootstrap.sh | bash
```

The script detects `x86_64` and `aarch64` on Linux and macOS, downloads the matching `popup` archive and SHA-256 sidecar from its GitHub Release, verifies it, and adds `~/.popup/bin` to bash, zsh, fish, or POSIX-shell startup files. Set `POPUP_HOME` before running it to choose another installation root; use `--no-modify-path` to leave shell files untouched. Set `POPUP_VERSION` to install a specific release, including a prerelease.

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/poplanguage/popup/master/scripts/bootstrap.ps1 | iex
```

The PowerShell installer uses the same GitHub Release SHA-256 verification, installs to `%USERPROFILE%\.popup\bin`, and writes `POPUP_HOME` and the bin directory to the user environment. Use `-NoModifyPath` when running the checked-out script to skip that environment change.

Popup requires a published manager archive for the detected target. If a target is not yet published, the installer reports that exact missing artifact instead of choosing another platform.

## Usage

```sh
popup install [version | channel:beta]
```

Install a Pop Lang toolchain. If no version is specified, the latest release is installed. A version may be written with or without its `v` prefix. `channel:beta` selects a release channel from the Index.

```sh
# Install the latest version
popup install

# Install a specific version
popup install v0.1.0-rc.3
```

The installer:

- detects the host platform (architecture and OS), including Linux, macOS, and Windows targets
- selects the exact matching, available ZIP artifact from a Pop Index release manifest
- verifies the manifest-provided SHA-256 digest before extraction
- downloads the archive with progress bar, speed, and ETA
- rejects unsafe or incomplete archives and extracts transactionally to
  `~/.popup/toolchains/<version>/`
- creates a `default` link (or Windows selection file) for the active toolchain
- writes `pop` and `pop-language-server` shims to `~/.popup/bin/`
- offers to add `~/.popup/bin` to your PATH

```sh
popup toolchains list
```

List installed toolchain versions.

```sh
popup toolchains default v0.1.0-rc.5
popup toolchains uninstall v0.1.0-rc.4
popup env fish
popup env powershell
```

`default` switches immediately among installed toolchains. `uninstall` refuses to remove the active toolchain. `env` prints safe activation commands for `sh`, bash, zsh, fish, PowerShell, or cmd; use it when a profile is managed by another tool:

For example, run `popup env fish` from fish and evaluate its output there, or copy the printed commands into the relevant shell profile.

## Directory structure

```text
~/.popup/
  bin/
    pop              # shim that delegates to the active toolchain
    pop-language-server
  toolchains/
    default -> v0.1.0-rc.3   # symlink to the active version (Unix)
    default.txt              # active version on Windows
    v0.1.0-rc.3/             # extracted toolchain files
```

## Configuration

`popup` respects the `POPUP_HOME` environment variable. If unset, it defaults to `~/.popup`. `POP_INDEX_URL` can point to a compatible Pop Index mirror; it defaults to `https://pop.squareweb.app`.
The generated shim retains the selected installation root; custom roots do not
fall back to `$HOME/.popup`.

## Uninstallation

Remove `~/.popup` manually. Remove the PATH line from your shell profile if you added it.

## Development

Prerequisites: Crystal >= 1.20.1

```sh
# Install dependencies
shards install

# Build
shards build

# Run tests
crystal spec
```

## Releasing

Push a semantic `v*` tag, or run **Publish Release** manually with a semantic tag. CI builds native `x86_64-unknown-linux-gnu` and `aarch64-unknown-linux-gnu` manager archives, uploads their SHA-256 sidecars, and creates the GitHub release used by `bootstrap.sh`.

## Contributing

1. Fork it (<https://github.com/poplanguage/popup/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [GalactHD](https://github.com/GalactHD) - creator and maintainer
