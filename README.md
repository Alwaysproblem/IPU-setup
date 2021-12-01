# IPU setup for Conda and Vscode

## Description

This is a bash script for conda wrapper to create a IPU related conda enviornment.

## Installation

poplar sdk installation from [Graphcore support](https://www.graphcore.ai/support)

**Note: This is not official bash installation script and only tested on Ubuntu 18.04**

## Usage

- Download SDK from Graphcore Support

- Download bash script

    ```bash
    $ wget -O $HOME/.ipuenv/popconda https://raw.githubusercontent.com/Alwaysproblem/IPU-setup/main/executable/popconda
    $ export PATH="$HOME/.ipuenv/:$PATH"
    $ popconda --help
    ```
