<p align="center">
    <a href="https://gitlab.rnl.tecnico.ulisboa.pt/rnl/nixrnl">
        <img src="https://gitlab.rnl.tecnico.ulisboa.pt/uploads/-/system/project/avatar/4709/nix-snowflake-ist.png" height="150"/>
    </a>
</p>

This repository contains the infrastructure setup for [RNL](https://rnl.tecnico.ulisboa.pt) (Rede das Novas Licenciaturas) using Nix[OS], a purely functional Linux distribution built on the Nix package manager.
The infrastructure is designed to support the various components and services required for running servers and labs at [DEI](https://dei.tecnico.ulisboa.pt).

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Goals](#goals)
- [How to create a live USB/ISO?](#how-to-create-a-live-usbiso)
- [How to add a new host?](#how-to-add-a-new-host)
- [How to deploy a new NixOS machine?](#how-to-deploy-a-new-nixos-machine)
- [How to update a machine configuration?](#how-to-update-a-machine-configuration)
- [How to add a new secret?](#how-to-add-a-new-secret)
- [How to update a secret?](#how-to-update-a-secret)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)

## Goals

- **Mono-repository**: All the infrastructure should be in a single repository.
- **Immutable**: The infrastructure should be immutable and changes should be easy to revert.
- **Versioned**: The infrastructure should be versioned and changes should be easy to track.
- **Reproducible**: The infrastructure should be reproducible and changes should be easy to test.
- **Secure**: The infrastructure should be secure and secrets should be encrypted.
- **Scalable**: The infrastructure should be scalable and easy to extend.

## How to create a live USB/ISO?

To create an ISO from a host configuration, you should run the following command:
```bash
nix build .#nixosConfigurations.<nixosConfiguration>.config.system.build.isoImage
```

Description of the arguments:
- `<nixosConfiguration>`: The name of the NixOS configuration to deploy. This is the name of the nixosConfiguration output in the `flake.nix` file.

You may want to use a nixosConfiguration from the `hosts/live` directory, as these configurations are designed to be used in live environments.

After the ISO is built, you can write it to a USB drive using the following command:
```bash
dd if=result/iso/<nixosConfiguration>.iso of=/dev/sdX status=progress
```

# How to add a new host?

To add a new host, you should create a new file in the `hosts` directory with the hostname of the machine (e.g. if the hostname is `example` the file should be named `example.nix`). \
_This file should import one profile of each category (`core`, `filesystems`, `os`, `type`)._

Try to look for an existing host with similar characteristics and copy the configuration from there. \
More information about the available profiles can be found in the profiles directory.

## How to deploy a new NixOS machine?

Start a shell with a development environment:
```bash
nix develop
```

And then run the following command to deploy a new machine:
```bash
deploy-anywhere .#<nixosConfiguration> root@<ip/hostname> [<sshHostKey>]
```
Description of the arguments:
- `<nixosConfiguration>`: The name of the NixOS configuration to deploy. This is the name of the nixosConfiguration output in the `flake.nix` file.
- `<ip/hostname>`: The IP address or hostname of the machine to deploy to.
- `<sshHostKey>` (Optional): The SSH host key of the machine to deploy to. This value should be the name of the secret in the `secrets/host-keys` directory (without the `.age`). If omitted, the VM cannot have secrets using Agenix and will generate a new SSH host key.

After the deployment is complete, you should be able to SSH into the machine.


## How to update a machine configuration?

To deploy a new configuration to a machine, you should run the following command:
```bash
nixos-rebuild <switch/boot> --flake .#<nixosConfiguration> --target-host <ip/hostname>
```
Description of the arguments:
- `<switch/boot>`: Use `switch` to switch to the new configuration without rebooting, or `boot` to only change the configuration on the next boot.
- `<nixosConfiguration>`: The name of the NixOS configuration to deploy. This is the name of the nixosConfiguration output in the `flake.nix` file.
- `<ip/hostname>`: The IP address or hostname of the machine to deploy to.

## How to add a new secret?

To add a new secret you should start a shell with a development environment and change the current directory to the `secrets` directory:
```bash
nix develop
cd secrets
```

Then you should edit the `secrets.nix` file and add a new entry to the output,
with the secret filename and the corresponding keys to encrypt it.

After adding the secret name to the file, run the following command to encrypt a file with the secret:
```bash
agenix -e <secretName>
```
**or**
```bash
echo -n "<secret>" | agenix -e <secretName>
```
Description of the arguments:
- `<secretName>`: The name of the secret to generate. This value should be the name written in the file `secrets.nix`.

After generating the secret, you should update the nixos configuration to use the new secret (if it's not a host key).

## How to update a secret?

To update a secret you should start a shell with a development environment and change the current directory to the `secrets` directory:
```bash
nix develop
cd secrets
```

Then you should encrypt the file again:
```bash
agenix -e <secretName>
```

Or if you only want to change the encryption keys, you can run:
```bash
agenix -r
```

## Contributing

If you want to contribute to this repository, you should start by creating an issue describing the changes you want to make.
After that, you should fork the repository and clone it:
```bash
git clone <your-fork-url>
```

Then you should create a new branch for your changes:
```bash
git checkout -b <issue-number>-<branch-name>
```

After making your changes, you should commit them and push them to your fork:
```bash
git add <files>
git commit -m "<commit-message>"
git push origin <branch-name>
```
The commit message should be a short description of the changes you made and should follow the convention of the repository.

Finally, you should open a pull request to the main repository.

## License

This repository is licensed under the MIT license.\
See the [LICENSE](LICENSE) file for more details.

## Contact

If you have any questions or suggestions, you can [create an issue](https://gitlab.rnl.tecnico.ulisboa.pt/rnl/nixrnl/-/issues/new) or [contact us](https://rnl.tecnico.ulisboa.pt/contactos/).

