
IPU environment initialization wrapper for conda environment creation.

The generated bash script can write environment variables to 
`$CONDA_PREFIX/etc/conda/activate.d` or `$CONDA_PREFIX/etc/conda/deactivate.d`
instead of `source enable.sh` manually after you create conda environment
with this wrapper. You alse can edit those configuration manually if your ipu configuration is changed
the path is `$CONDA_PREFIX/etc/conda/activate.d/ipu_set_env.sh` or
`$CONDA_PREFIX/etc/conda/deactivate.d/ipu_unset_env.sh`

you can declare the environment variables for these default path:
    `$IPUCONDA_EXECUTABLE_CACHE_PATH` is the default value of `$EXECUTABLE_CACHE_PATH`
    `$IPUCONDA_IPUOF_CONFIG_PATH` is the default value of `$IPUOF_CONFIG_PATH`
    `$IPUCONDA_POP_DIR_BASE` is the default value of `$POP_DIR_BASE`

usage:
    IPUconda [conda create enviornment command]
    for example:
        $ IPUconda conda create -n my-ipu-env python=3.6

    -h, --help: print helpful message
    setdefault: set the default enviornment var for IPU config