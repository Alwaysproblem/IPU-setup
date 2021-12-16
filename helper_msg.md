
IPU environment initialization wrapper for conda environment creation.

The generated bash script can write environment variables to 
`$CONDA_PREFIX/etc/conda/activate.d` or `$CONDA_PREFIX/etc/conda/deactivate.d`
instead of `source enable.sh` manually after you create conda environment
with this wrapper. You alse can edit those configuration manually if your ipu configuration is changed
the path is `$CONDA_PREFIX/etc/conda/activate.d/ipu_set_env.sh` or
`$CONDA_PREFIX/etc/conda/deactivate.d/ipu_unset_env.sh`

some enviornment variables description:

For default directory:

    POP_DIR_BASE
        |
        |
        --- sdk (hard code)
             |
             |
             --- POPSDK_BASE (for example sdk 2.3.1)
             |      |
             |      |
             |      --- POPLAR_BASE
             |      |
             |      --- POPART_BASE
             |
             --- POPSDK_BASE (for example sdk 2.4)
                    |
                    |
                    --- POPLAR_BASE
                    |
                    --- POPART_BASE

if you assgined POP_DIR_BASE, you can choose from the multiple versions of sdk.
if you assgined POPSDK_BASE, you can only use the popsdk you specified
you also can specify the `POPLAR_BASE` `POPART_BASE` respectly.

These vars need to be set through `popconda setdefault` for the first time

`EXECUTABLE_CACHE_PATH`: executable graph cache path
`IPUOF_CONFIG_PATH`: IPU configuration file
`POP_DIR_BASE`: sdk base directory
`TMPDIR`: tempary variables stored path
`MAX_COMPILATION_THREADS`: max thread number for compilation

usage:
    IPUconda [conda create enviornment command]
    for example:
        $ IPUconda setdefaut
        $ IPUconda <options> -- conda create -n my-ipu-env python=3.6
        $ IPUconda update

    if you have already set the default configuration
    you can run 
        $ IPUconda -- conda create -n my-ipu-env python=3.6

    setdefault: set the default enviornment var for IPU configuration.

    udpate: update the bash script from github repository.

    -h, --help: print helpful message

    -ecp, --executable_cache_path: executable graph cache path

    -icf, --ipuof_config_path: IPU configuration file

    -popdir, --popdir_base: sdk base directory

    -popsdk, --popsdk_base: sdk directory

    -poplar, --poplar_base: poplar directory

    -popart, --popart_base: popart directory

    -f, --framework: the machine learning framework one of [tf1, tf2, jax, popart, torch]
