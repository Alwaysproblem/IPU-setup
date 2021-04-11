# IPU setup for Conda and Vscode

This is a bash shell script for poplar sdk installation from [Graphcore support](https://www.graphcore.ai/support)

**Note: This is not official bash installation script**

## Usage

- Download SDK from Graphcore Support

- Download bash script

    ```bash
    $ wget https://raw.githubusercontent.com/Alwaysproblem/IPU-setup/main/ipu-setup.sh
    $ bash ipu-setup.sh
    ```

- After that, follow the instructions

## Description

- `ipu-setup.sh` will generate 3 executable files

    1. `IPUconda` will create 2 intializing IPU environment bash sripts can be executed automatically before running `conda activate` and `conda deactivate`
    2. `setupVscode` will create 3 files that make setting up vscode project easily.
    3. `popvision_enable`, it is wrapper for logging information for popvision software. You can use like `popvision_enable python you_python_file.py` and the directory `popvision` is for popvision software.  

- Change SDK path manually if you IPU configuration is changed.