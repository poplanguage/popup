# popup

A toolchain manager for Pop Language. Downloads, installs, and manages Pop compiler and runtime distributions.

`popup` handles toolchain distribution independently from `pop`, the language and package command. It fetches verified release artifacts and detects the host platform to install the correct binary.

## Installation

1. ### Build from source:

```sh
git clone git@github.com:poplanguage/popup
cd popup
shards install
shards build
```

2. ### Bootstrap script (Work In Progress)

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
popup install v0.1.0
```

The installer:
- detects the host platform (architecture and OS)
- fetches the matching release artifact from the `poplanguage/pop` GitHub repository
- downloads the binary to the current directory

## Uninstallation

Run the bootstrap script and select the uninstall option, or remove `~/.popup` manually.

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
