# popup

> **WARNING: This software is under active development and is unstable.**

A toolchain manager for Pop Language. Downloads, installs, and manages Pop compiler and runtime distributions.

`popup` handles toolchain distribution independently from `pop`, the language and package command. It fetches verified release artifacts and detects the host platform to install the correct binary.

## Installation

### Build from source

```sh
git clone git@github.com:poplanguage/popup
cd popup
shards install
shards build
```

### Bootstrap script (WIP)

```sh
curl -fsSL https://raw.githubusercontent.com/poplanguage/popup/master/scripts/bootstrap.sh | bash
```

## Usage

```sh
popup install [version]
```

Install a Pop Lang toolchain. If no version is specified, the latest release is installed.

```sh
# Install the latest version
popup install

# Install a specific version
popup install v0.1.0-rc.3
```

The installer:

- detects the host platform (architecture and OS)
- selects the exact matching release artifact and `.sha256` file from the
  `poplanguage/pop` GitHub repository
- verifies the SHA-256 digest before extraction
- downloads the archive with progress bar, speed, and ETA
- rejects unsafe or incomplete archives and extracts transactionally to
  `~/.popup/toolchains/<version>/`
- creates a `default` symlink to the active toolchain
- writes a `pop` shim to `~/.popup/bin/pop`
- offers to add `~/.popup/bin` to your PATH

```sh
popup toolchains list
```

List installed toolchain versions.

## Directory structure

```text
~/.popup/
  bin/
    pop              # shim that delegates to the active toolchain
  toolchains/
    default -> v0.1.0-rc.3   # symlink to the active version
    v0.1.0-rc.3/             # extracted toolchain files
```

## Configuration

`popup` respects the `POPUP_HOME` environment variable. If unset, it defaults to `~/.popup`.
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

## Contributing

1. Fork it (<https://github.com/poplanguage/popup/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [GalactHD](https://github.com/GalactHD) - creator and maintainer
