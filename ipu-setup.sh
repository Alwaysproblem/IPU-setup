#!/bin/bash

# main file:
# 1. start
# 2. read tar file path untar to directory (default $HOME/sdk/ also can be customed)
# 3. untar the file to that directory and decode version info.
# 4. choosing the virtual environment (conda or venv)
# 5. read generated file path (_generated_file_path) from console (deault is $HOME/.ipuenv) and add to PATH and echo to SHELL(default) (.zshrc or bashrc)
# 6. generate a ipu-conda-setup-file or ipu-venv-setup-file to `_generated_file_path`
# 7. if vscode generate-vscode-setup-file to `_generated_file_path`
# 8. generate source env file for terminal (manually activate) to _generated_file_path
# 9. done

# ipu-conda-setup-file 
# 1. add environment variables to $CONDA_PREFIX/etc/conda/activate.d/*.sh 
# 2. add environment variables to $CONDA_PREFIX/etc/conda/deactivate.d/*.sh 
 
# ipu-venv-setup-file (TODO)

# generate-vscode-setup-file
# 1. read project path (default is PWD) and `source env` mode flag
# 2. generate .ipu.env file if .vscode exsists else make directory
# 3. if `source env` mode there is no need to change vscode setting about intergrate terminal else generate terminal.env.sh to project_path/.vscode
# 4. change setting.json
# 5. generate `IpuDebugEnv` and `IpuEnv` wrapper to .vscode path and add .vscode path to PATH

# set -ex

_IPU_DRIVER_TAR_FILE=""
_INPUTS=""

# BASE_SDK_DIR="/mnt/scratch001/custeng-cn-scratch/yongxiy"
BASE_SDK_DIR="${HOME}"
POP_BASE_DIR="${BASE_SDK_DIR}/sdk"

POP_SDK_VERSION="2.0.0+481-79b41f85d1"
POPART_VERSION="2.0.0+108156-165bbd8a64"
POPLAR_VERSION="2.0.0+108156-165bbd8a64"

POP_SDK_BASE_DIR="${HOME}/sdk"
POPART_BASE_DIR="${HOME}/sdk/${POPART_VERSION}"
POPLAR_BASE_DIR="${HOME}/sdk/${POPLAR_VERSION}"

_GEN_SRIPT_BASE_PATH="${HOME}/.ipuenv"

### this can be changed ####
GCDA_MONITOR=1
TF_CPP_VMODULE='poplar_compiler=1,poplar_executable=1'
# export TF_CPP_VMODULE='poplar_compiler=1'
EXECUTABLE_CACHE_PATH="${HOME}/.cache"
TF_POPLAR_FLAGS="--max_compilation_threads=40 --executable_cache_path=${EXECUTABLE_CACHE_PATH} --show_progress_bar=true"
# TMPDIR="${BASE_DIR_SCOTTY}/tmp"
if [[ -z ${TMPDIR} ]]; then
  TMPDIR="/tmp"
fi
IPUOF_CONFIG_PATH="${POP_BASE_DIR}/pod16_ipuof.conf"
###

function success_or_warning(){
  _msg=$1
  if [ $? -ne 0 ];then
    printf "\e[93m%s\e[0m" _msg
  fi
}

function success_or_die()
{
  _msg=$1
  if [ $? -ne 0 ];then
    printf "%s\n" _msg
    exit 1
  fi
}

function check_file_exist()
{
  _file=$1
  if [ ! -f $_file ];then
    printf "%s is not file or file does not exist\n" $_file
    exit 1
  fi	
}

function check_dir_exist()
{
  _dir=$1
  if [ ! -d $_dir ];then
    printf "%s is not dir or dir does not exist\n" $_dir 
    exit 1
  fi	
}

function check_file_already_exist()
{
  _file=$1
  if [ -d $_file ];then
    printf "file %s already exist\n" $_file 
    exit 1
  fi	
}

function check_dir_already_exist()
{
  _dir=$1
  if [ -d $_dir ];then
    printf "dir %s already exist\n" $_dir 
    exit 1
  fi	
}

function mkdir_safe()
{
  _dir=$1
  mkdir -p $_dir
  success_or_die "create new directory failed ${_dir}"
}

function rm_safe()
{
  _dir=$1
  if [ -d $_dir ];then
    rm -rf $_dir
    success_or_die "can not remove directory ${_dir}"
  elif [ -f $_dir ];then
    # printf "%s is a regular file\n" ${_dir}
    rm -rf $_dir
    success_or_die "can not remove file ${_dir}"
  fi
}

function _input() {
  echo "${1}"
  if [[ $# -eq 2 ]]; then
    echo -ne "[default: ${2}] >> "
  else
    echo -ne ">> "
  fi
  read _INPUTS
}

function _input_with_check_file() {
  for i in {0..2}; do
    _input "$1"
    if [ ! -z "${_INPUTS}" ];then
      if [ ! -f ${_INPUTS} ]; then
        printf "\e[31m%s is not file or file does not exist\e[0m\n" ${_INPUTS}
      else
        printf "%s found\n" ${_INPUTS}
        break
      fi
    fi
    if [[ i -eq 2 ]]; then
      echo "please input the directory of ipu sdk tar file."
      exit 1
    fi
  done
}

function _input_tar_file_path(){
  _input_with_check_file "please input the directory of ipu sdk tar file."
  _IPU_DRIVER_TAR_FILE=${_INPUTS}
}

function _input_base_dir(){
  _input "please enter installation directory" "${BASE_SDK_DIR}"
  if [[ ${_INPUTS} != "" ]]; then
    if [[ ${_INPUTS} == /* ]]; then
      BASE_SDK_DIR=${_INPUTS}
    else
      BASE_SDK_DIR="${PWD}/${_INPUTS}"
    fi
  fi
}

function _input_script_file_path(){
  _input "please enter ipu environment initialization file directory" "${_GEN_SRIPT_BASE_PATH}"
  if [[ ${_INPUTS} != "" ]]; then
    if [[ ${_INPUTS} == /* ]]; then
      _GEN_SRIPT_BASE_PATH=${_INPUTS}
    else
      _GEN_SRIPT_BASE_PATH="${PWD}/${_INPUTS}"
    fi
  fi
}

function _input_config_env(){
  _input "please enter executable graph cache path (absolute path):" ${EXECUTABLE_CACHE_PATH}
  EXECUTABLE_CACHE_PATH=${_INPUTS:-${EXECUTABLE_CACHE_PATH}}
  if [ ! -d ${EXECUTABLE_CACHE_PATH} ];then
    mkdir -p ${EXECUTABLE_CACHE_PATH}
    success_or_warning "failed to create directory ${EXECUTABLE_CACHE_PATH}"
  fi
  
  _input "please enter tempary variables stored path (absolute path):" ${TMPDIR}
  TMPDIR=${_INPUTS:-${TMPDIR}}
  if [ ! -d ${TMPDIR} ];then
    mkdir -p ${TMPDIR}
    success_or_warning "failed to create directory ${TMPDIR}"
  fi

  _input "please enter tempary variables stored path (absolute path):" ${IPUOF_CONFIG_PATH}
  IPUOF_CONFIG_PATH=${_INPUTS:-${IPUOF_CONFIG_PATH}}
  check_file_exist ${IPUOF_CONFIG_PATH}
}

function _get_default_shell() {
  _shell=$(echo ${SHELL} | awk -F/ '{print $3}')
  if [[ $_shell == "zsh" ]]; then
    echo -e "export PATH=\$PATH:${_GEN_SRIPT_BASE_PATH}" >> ${HOME:-$ZDOTDIR}/.zshrc
    # echo -e "export PATH=\$PATH:${_GEN_SRIPT_BASE_PATH}"
  elif [[ $_shell == "bash" ]]; then
    echo -e "export PATH=\$PATH:${_GEN_SRIPT_BASE_PATH}" >> $HOME/.bashrc
    # echo -e "export PATH=\$PATH:${_GEN_SRIPT_BASE_PATH}"
  fi
}

function untar_sdk()
{
  local tarball="$1"
  local _root_dir="$2"
  local _dir=${_root_dir}/sdk/
  mkdir_safe ${_dir}
  check_dir_exist ${_dir}
  tar zxvf $tarball -C $_dir
  success_or_die "untar the ipu sdk failed"
}

function _extract_version_info(){
  local _tar_name=$(basename $1)
  _sdk_dir=$(echo $_tar_name | sed -e 's/\.tar.gz//' -e 's/\.tar//')
  local _VERSION=$(echo $_tar_name | awk -F '-' '{printf ("%s-%s",$3,$4)}' | sed 's#.tar.gz##')
  echo -ne "$_VERSION"
}

function _extract_sdk_version_info(){
  local ROOT_DIR=$1
  POP_SDK_VERSION=$(_extract_version_info ${ROOT_DIR})
}

function _extract_popart_version_info(){
  local ROOT_DIR=$1
  local _dir=$(find $ROOT_DIR -maxdepth 1 -name "popart-*")
  POPART_VERSION=$(_extract_version_info ${_dir})
  POPART_BASE_DIR=${_dir}
}

function _extract_poplar_version_info(){
  local ROOT_DIR=$1
  local _dir=$(find $ROOT_DIR -maxdepth 1 -name "poplar-*")
  POPLAR_VERSION=$(_extract_version_info ${_dir})
  POPLAR_BASE_DIR=${_dir}
}

#### conda ####

function conda_create_env_file(){
  local _GEN_SRIPT_CONDA="${_GEN_SRIPT_BASE_PATH}/IPUconda"
  # cat <<eof > IPUconda
  cat <<eof > "${_GEN_SRIPT_CONDA}"
#!/bin/bash

function _create_conda_activate_script(){
  local file_path=\$1
  cat <<EOF > "\${file_path}"
#!/bin/bash
# set -ex

export GCDA_MONITOR=$GCDA_MONITOR
export TF_CPP_VMODULE="$TF_CPP_VMODULE"
export TF_POPLAR_FLAGS="$TF_POPLAR_FLAGS"
export TMPDIR="$TMPDIR"
export IPUOF_CONFIG_PATH="$IPUOF_CONFIG_PATH"

export _OLD_TMPDIR=\\\$TMPDIR
export _OLD_CMAKE_PREFIX_PATH=\\\$CMAKE_PREFIX_PATH
export _OLD_PATH=\\\${PATH#\\\$CONDA_PREFIX/bin:}
export _OLD_CPATH=\\\$CPATH
export _OLD_LIBRARY_PATH=\\\$LIBRARY_PATH
export _OLD_LD_LIBRARY_PATH=\\\$LD_LIBRARY_PATH
export _OLD_OMPI_CPPFLAGS=\\\$OMPI_CPPFLAGS
export _OLD_OPAL_PREFIX=\\\$OPAL_PREFIX
export _OLD_PYTHONPATH=\\\$PYTHONPATH


function check_file_exist()
{
  _file=\\\$1
  if [ ! -f \\\$_file ];then
    printf "\e[93m%s is not file or file does not exist\n\e[0m" \\\$_file
  fi	
}

check_file_exist "$POPART_BASE_DIR/enable.sh"
pushd $POPART_BASE_DIR
  source "$POPART_BASE_DIR/enable.sh"
popd

check_file_exist "$POPLAR_BASE_DIR/enable.sh"
pushd $POPLAR_BASE_DIR
  source "$POPLAR_BASE_DIR/enable.sh"
popd

# set +ex
EOF
}

function _create_conda_deactivate_script(){
  local file_path=\$1
  cat <<EOF > "\${file_path}"
#!/bin/bash
# set -ex

export TMPDIR=\\\$_OLD_TMPDIR
export CMAKE_PREFIX_PATH=\\\$_OLD_CMAKE_PREFIX_PATH
export PATH=\\\$_OLD_PATH
export CPATH=\\\$_OLD_CPATH
export LIBRARY_PATH=\\\$_OLD_LIBRARY_PATH
export LD_LIBRARY_PATH=\\\$_OLD_LD_LIBRARY_PATH
export OMPI_CPPFLAGS=\\\$_OLD_OMPI_CPPFLAGS
export OPAL_PREFIX=\\\$_OLD_OPAL_PREFIX
export PYTHONPATH=\\\$_OLD_PYTHONPATH

unset GCDA_MONITOR
unset TF_CPP_VMODULE
unset TF_POPLAR_FLAGS
unset IPUOF_CONFIG_PATH
unset POPLAR_SDK_ENABLED
unset _OLD_TMPDIR
unset _OLD_CMAKE_PREFIX_PATH
unset _OLD_PATH
unset _OLD_CPATH
unset _OLD_LIBRARY_PATH
unset _OLD_LD_LIBRARY_PATH
unset _OLD_OMPI_CPPFLAGS
unset _OLD_OPAL_PREFIX
unset _OLD_PYTHONPATH

# set +ex
EOF
}

function conda_wrapper_help_msg(){
  echo ""
  echo "IPU environment initialization wrapper for conda environment creation."
  echo ""
  echo "The generated bash script can write environment variables to "
  echo "\\\`\\\$CONDA_PREFIX/etc/conda/activate.d\\\` or \\\`\\\$CONDA_PREFIX/etc/conda/deactivate.d\\\`"
  echo "instead of \\\`source enable.sh\\\` manually after you create conda environment"
  echo "with this wrapper. You alse can edit those configuration manually if your ipu configuration is changed"
  echo "the path is \\\`\\\$CONDA_PREFIX/etc/conda/activate.d/ipu_set_env.sh\\\` or"
  echo "\\\`\\\$CONDA_PREFIX/etc/conda/deactivate.d/ipu_unset_env.sh\\\`"
  echo ""
  echo "usage:"
  echo "    IPUconda [conda create enviornment command]"
  echo "    for example:"
  echo "        \\\$ IPUconda conda create -n my-ipu-env python=3.6"
  echo ""
  echo "    -h, --help: print helpful message"
}


function extract_condaenv_name(){
    local conda_str=\$1
    local _prefix=""
    local _env_name=""
    while [ "\$1" != "" ]; do
        case \$1 in
            -p | --prefix)          shift
                                    _prefix=\$1
                                    ;;
            -n | --name )           shift
                                    _env_name=\$1
                                    ;;
        esac
        shift
    done
    if [[ \${_prefix} != "" && \$_env_name != "" ]]; then
        if [[ \${_prefix} == /* ]]; then
            _prefix=\${_prefix}
        else
            _prefix="\${PWD}/\${_prefix}"
        fi
        _CONDA_ENV_NAME="\${_prefix}/\${_env_name}"
    else
        _CONDA_ENV_NAME="\${_prefix}\${_env_name}"
    fi
    echo \${_CONDA_ENV_NAME}
}

if [[ \$1 != "conda" ]]; then
    conda_wrapper_help_msg
    exit 0
fi

_CONDA_CMD=\$@
echo "\${_CONDA_CMD}"
extract_condaenv_name \${_CONDA_CMD}
bash -ic "\${_CONDA_CMD}"

_CONDA_ENV_DEFAULT_PREFIX="\$(dirname \$(dirname \$(which conda)))/envs"
if [[ \${_CONDA_ENV_NAME} != /* ]]; then
    mkdir -p "\${_CONDA_ENV_DEFAULT_PREFIX}/\${_CONDA_ENV_NAME}/etc/conda/activate.d/"
    mkdir -p "\${_CONDA_ENV_DEFAULT_PREFIX}/\${_CONDA_ENV_NAME}/etc/conda/deactivate.d/"
    _create_conda_activate_script "\${_CONDA_ENV_DEFAULT_PREFIX}/\${_CONDA_ENV_NAME}/etc/conda/activate.d/ipu_set_env.sh"
    _create_conda_deactivate_script "\${_CONDA_ENV_DEFAULT_PREFIX}/\${_CONDA_ENV_NAME}/etc/conda/deactivate.d/ipu_unset_env.sh"
else
    mkdir -p "\${_CONDA_ENV_NAME}/etc/conda/activate.d/"
    mkdir -p "\${_CONDA_ENV_NAME}/etc/conda/deactivate.d/"
    _create_conda_activate_script "\${_CONDA_ENV_NAME}/etc/conda/activate.d/ipu_set_env.sh"
    _create_conda_deactivate_script "\${_CONDA_ENV_NAME}/etc/conda/deactivate.d/ipu_unset_env.sh"
fi

if [[ \$? != 0 ]]; then
    conda_wrapper_help_msg
    exit 0
fi
eof
chmod +x ${_GEN_SRIPT_CONDA}
}

#### vscode ####

function vscode_setup_file(){
  # local _GEN_SRIPT_VSCODE="bb.sh"
  local _GEN_SRIPT_VSCODE="${_GEN_SRIPT_BASE_PATH}/setupVscode"
  cat <<eof > "${_GEN_SRIPT_VSCODE}"
#!/bin/bash

function vscode_files_help_msg(){
  echo ""
  echo "Initialize vscode settings under workspace/.vscode only for Linux"
  echo ""
  echo "1. settings.json (the settings for vscode project)"
  echo "2. .ipu.env (define the variables for debug and run through trangles button)"
  echo "3. terminal.env.sh (automatically source ipu env when initiate integrate terminal if you are not using conda)"
  echo ""
  echo "usage:"
  echo "  -p, --project   the path to your workspace"
  echo "  -h, --help      print this help message"
  echo ""
}

function gen_envfile(){
  local workspace=\$1
  local file_name=".ipu.env"

  echo -ne "" > "\${workspace}/.vscode/\${file_name}"

  echo "GCDA_MONITOR=$GCDA_MONITOR" >> "\${workspace}/.vscode/\${file_name}"
  echo "TF_CPP_VMODULE='$TF_CPP_VMODULE'" >> "\${workspace}/.vscode/\${file_name}"
  echo "TF_POPLAR_FLAGS='$TF_POPLAR_FLAGS'" >> "\${workspace}/.vscode/\${file_name}"
  echo "TMPDIR=$TMPDIR" >> "\${workspace}/.vscode/\${file_name}"
  echo "IPUOF_CONFIG_PATH=$IPUOF_CONFIG_PATH" >> "\${workspace}/.vscode/\${file_name}"
  echo "CMAKE_PREFIX_PATH=$CMAKE_PREFIX_PATH" >> "\${workspace}/.vscode/\${file_name}"
  echo "PATH=$PATH" >> "\${workspace}/.vscode/\${file_name}"
  echo "CPATH=$CPATH" >> "\${workspace}/.vscode/\${file_name}"
  echo "LIBRARY_PATH=$LIBRARY_PATH" >> "\${workspace}/.vscode/\${file_name}"
  echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >> "\${workspace}/.vscode/\${file_name}"
  echo "OMPI_CPPFLAGS=$OMPI_CPPFLAGS" >> "\${workspace}/.vscode/\${file_name}"
  echo "OPAL_PREFIX=$OPAL_PREFIX" >> "\${workspace}/.vscode/\${file_name}"
  echo "PYTHONPATH=$PYTHONPATH" >> "\${workspace}/.vscode/\${file_name}"
  echo "POPLAR_SDK_ENABLED=$POPLAR_SDK_ENABLED" >> "\${workspace}/.vscode/\${file_name}"
}

function gen_terminial_init_script(){
  local workspace=\$1
  local file_name="terminal.env.sh"
  cat <<EOF > "\${workspace}/.vscode/\${file_name}"
#!/bin/bash
# set -ex

export GCDA_MONITOR=$GCDA_MONITOR
export TF_CPP_VMODULE="$TF_CPP_VMODULE"
export TF_POPLAR_FLAGS="$TF_POPLAR_FLAGS"
export TMPDIR="$TMPDIR"
export IPUOF_CONFIG_PATH="$IPUOF_CONFIG_PATH"

function check_file_exist()
{
  _file=\\\$1
  if [ ! -f \\\$_file ];then
    printf "\e[93m%s is not file or file does not exist\n\e[0m" \\\$_file
  fi	
}

check_file_exist "$POPART_BASE_DIR/enable.sh"
pushd $POPART_BASE_DIR
  source "$POPART_BASE_DIR/enable.sh"
popd

check_file_exist "$POPLAR_BASE_DIR/enable.sh"
pushd $POPLAR_BASE_DIR
  source "$POPLAR_BASE_DIR/enable.sh"
popd

# set +ex
EOF
}

function _modify_setting_json(){
  local file=\$1
  local total_line=\$(wc -l \${file} | awk -F' ' '{print \$1}')
  local last_line=\$((total_line - 1))

  local a=0
  cat \${file} | while read LINE
  do
    echo \$LINE
  done

}

function _add_to_setting_json(){
  local workspace=\$1
  if [[ ! -f "\$workspace/.vscode/settings.json" ]]; then
    cat <<EOF > "\$workspace/.vscode/settings.json"
{
    "python.envFile": "\\\${workspaceFolder}/.vscode/.ipu.env",
    // this is for running bash script before initiating internal terminal
    "terminal.integrated.shellArgs.linux": ["-c", "source .vscode/terminal.env.sh; zsh"],
}
EOF
  else
    sed -i '1a "terminal.integrated.shellArgs.linux": ["-c", "source .vscode/terminal.env.sh; zsh"],",' "\$workspace/.vscode/settings.json"
    sed -i '1a // this is for running bash script before initiating internal terminal",' "\$workspace/.vscode/settings.json"
    sed -i '1a "python.envFile": "\${workspaceFolder}/.vscode/.ipu.env",' "\$workspace/.vscode/settings.json"
  fi
}


while [ "\$1" != "" ]; do
    case \$1 in
        -p | --project)          shift
                                _project=\$1
                                ;;
        -h | --help )           vscode_files_help_msg
                                exit 0
                                ;;
        *)                      vscode_files_help_msg
                                exit 0
                                ;;
    esac
    shift
done

if [[ \${_project} != "" ]]; then
  if [[ \${_project} == /* ]]; then
    _project=\${_project}
  else
    _project="\${PWD}/\${_project}"
  fi
else
  _project="\${PWD}"
fi

if [[ -d "\${_project}" ]]; then
  if [[ ! -d "\${_project}/.vscode" ]];then
    mkdir -p "\${_project}/.vscode"
  fi
else
  printf "\e[93m%s does not exsists.\n\e[0m" \${_project}
  exit 0
fi



# set -ex 

gen_envfile \${_project}
gen_terminial_init_script \${_project}
_add_to_setting_json \${_project}

# set +ex
eof
chmod +x ${_GEN_SRIPT_VSCODE}
}

function _ipu_popvision_python_wrapper(){
  # local _GEN_SRIPT_VSCODE="ccc.sh"
  local _GEN_SRIPT_VSCODE="${_GEN_SRIPT_BASE_PATH}/popvision_enable"
  cat <<eof > "${_GEN_SRIPT_VSCODE}"
#!/bin/bash

export POPLAR_ENGINE_OPTIONS='{"autoReport.all":"true", "autoReport.directory":"./popvision"}'
bash -ic \$@
unset POPLAR_ENGINE_OPTIONS
eof
chmod +x ${_GEN_SRIPT_VSCODE}
}

# function _extract_pop_version_info(){
#   local _tar_name=$(basename $1)
#   _sdk_dir=$(echo $_tar_name | sed -e 's/\.tar.gz//' -e 's/\.tar//')
#   local _VERSION=$(echo $_tar_name | awk -F '-' '{printf ("%s-%s",$4,$5)}' | sed 's#.tar.gz##')
#   echo -ne "$_VERSION"
# }

function _summary_info_before_untar(){
  echo ""
  echo "The poplar sdk base directory: ${BASE_SDK_DIR}"
  echo -e "The poplar sdk directory: ${POP_BASE_DIR}"
  echo -e "The script generated wil be place to: ${_GEN_SRIPT_BASE_PATH}"
  echo "The executable cache path for compiling graph: ${EXECUTABLE_CACHE_PATH}"
  echo "tmp directory: ${TMPDIR}"
  echo "Ipu configuration file: ${IPUOF_CONFIG_PATH}"
  echo ""
  echo "comfirm installation (y or n)"
  echo -ne ">> "
  read vars
  if [[ $vars != "" ]]; then
    if [[ $vars != y* ]]; then
      exit 0
    fi
  else
    exit 0
  fi
}

function main(){
  # set -ex
  _input_tar_file_path
  # echo -e ${_IPU_DRIVER_TAR_FILE}
  _input_base_dir
  POP_BASE_DIR="${BASE_SDK_DIR}/sdk"
  _input_script_file_path
  mkdir_safe ${_GEN_SRIPT_BASE_PATH}
  _input_config_env

  _summary_info_before_untar

  untar_sdk "${_IPU_DRIVER_TAR_FILE}" "${BASE_SDK_DIR}"
  POP_ROOT="$(find ${POP_BASE_DIR} -maxdepth 1 -name 'poplar_sdk-*')"

  _extract_sdk_version_info "${POP_ROOT}"
  _extract_popart_version_info "${POP_ROOT}"
  _extract_poplar_version_info "${POP_ROOT}"

  check_file_exist "${POPART_BASE_DIR}/enable.sh"
  pushd ${POPART_BASE_DIR}
    source enable.sh
  popd

  check_file_exist "${POPLAR_BASE_DIR}/enable.sh"
  pushd ${POPLAR_BASE_DIR}
    source enable.sh
  popd

  conda_create_env_file
  vscode_setup_file
  _ipu_popvision_python_wrapper
  _get_default_shell

  # set +ex
}

function __debug(){

  _input_tar_file_path
  echo -e ${_IPU_DRIVER_TAR_FILE}
  _input_base_dir
  echo ${BASE_SDK_DIR}
  POP_BASE_DIR="${BASE_SDK_DIR}/sdk"
  echo -e "${POP_BASE_DIR}"
  _input_script_file_path
  echo -e "${_GEN_SRIPT_BASE_PATH}"

  _input_config_env
  echo "${EXECUTABLE_CACHE_PATH}"
  echo "${TMPDIR}"
  echo "${IPUOF_CONFIG_PATH}"

  # untar_sdk "${_IPU_DRIVER_TAR_FILE}" "${BASE_SDK_DIR}"
  SDK_PATH_AFTER_UNTAR="$(find ${POP_BASE_DIR} -maxdepth 1 -name "poplar_sdk*")"
  # SDK_PATH_AFTER_UNTAR="find ${POP_BASE_DIR} -name 'poplar_sdk' $(basename ${_IPU_DRIVER_TAR_FILE})"
  POP_ROOT="$(echo ${SDK_PATH_AFTER_UNTAR} | sed -e 's/\.tar.gz//' -e 's/\.tar//')"

  echo "${POP_ROOT}"
  _extract_sdk_version_info "${POP_ROOT}"
  _extract_popart_version_info "${POP_ROOT}"
  _extract_poplar_version_info "${POP_ROOT}"

  echo "${POPART_BASE_DIR}"
  echo "${POPLAR_BASE_DIR}"

  echo "${POP_SDK_VERSION}"
  echo "${POPART_VERSION}"
  echo "${POPLAR_VERSION}"

  # conda_create_env_file
  # vscode_setup_file
  # _ipu_popvision_python_wrapper
  # _get_default_shell

  # untar_sdk "${_IPU_DRIVER_TAR_FILE}" "${BASE_SDK_DIR}"
  # SDK_PATH_AFTER_UNTAR="${POP_BASE_DIR}/$(basename ${_IPU_DRIVER_TAR_FILE})"
  # POP_ROOT="$(echo ${SDK_PATH_AFTER_UNTAR} | sed -e 's/\.tar.gz//' -e 's/\.tar//')"

  # _extract_sdk_version_info "${POP_ROOT}"
  # _extract_popart_version_info "${POP_ROOT}"
  # _extract_poplar_version_info "${POP_ROOT}"

  # check_file_exist "$POPART_BASE_DIR/enable.sh"
  # pushd $POPART_BASE_DIR
  #   source enable.sh
  # popd

  # check_file_exist "$POPLAR_BASE_DIR/enable.sh"
  # pushd $POPLAR_BASE_DIR
  #   source enable.sh
  # popd
}

main
# set -ex
# __debug
# set +ex
