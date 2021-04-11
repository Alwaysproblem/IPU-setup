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
  local workspace=$1
  local file_name=".ipu.env"

  echo -ne "" > "${workspace}/.vscode/${file_name}"

  echo "GCDA_MONITOR=1" >> "${workspace}/.vscode/${file_name}"
  echo "TF_CPP_VMODULE='poplar_compiler=1,poplar_executable=1'" >> "${workspace}/.vscode/${file_name}"
  echo "TF_POPLAR_FLAGS='--max_compilation_threads=40 --executable_cache_path=/root/.cache --show_progress_bar=true'" >> "${workspace}/.vscode/${file_name}"
  echo "TMPDIR=/tmp" >> "${workspace}/.vscode/${file_name}"
  echo "IPUOF_CONFIG_PATH=/root/sdk/pod16_ipuof.conf" >> "${workspace}/.vscode/${file_name}"
  echo "CMAKE_PREFIX_PATH=" >> "${workspace}/.vscode/${file_name}"
  echo "PATH=/root/anaconda3/bin:/root/anaconda3/condabin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" >> "${workspace}/.vscode/${file_name}"
  echo "CPATH=" >> "${workspace}/.vscode/${file_name}"
  echo "LIBRARY_PATH=" >> "${workspace}/.vscode/${file_name}"
  echo "LD_LIBRARY_PATH=" >> "${workspace}/.vscode/${file_name}"
  echo "OMPI_CPPFLAGS=" >> "${workspace}/.vscode/${file_name}"
  echo "OPAL_PREFIX=" >> "${workspace}/.vscode/${file_name}"
  echo "PYTHONPATH=" >> "${workspace}/.vscode/${file_name}"
  echo "POPLAR_SDK_ENABLED=" >> "${workspace}/.vscode/${file_name}"
}

function gen_terminial_init_script(){
  local workspace=$1
  local file_name="terminal.env.sh"
  cat <<EOF > "${workspace}/.vscode/${file_name}"
#!/bin/bash
# set -ex

export GCDA_MONITOR=1
export TF_CPP_VMODULE="poplar_compiler=1,poplar_executable=1"
export TF_POPLAR_FLAGS="--max_compilation_threads=40 --executable_cache_path=/root/.cache --show_progress_bar=true"
export TMPDIR="/tmp"
export IPUOF_CONFIG_PATH="/root/sdk/pod16_ipuof.conf"

function check_file_exist()
{
  _file=\$1
  if [ ! -d \$_file ];then
    printf "\e[93m%s is not file or file does not exist\n\e[0m" \$_file
  fi
}

check_file_exist "/root/sdk/2.0.0+108156-165bbd8a64/enable.sh"
pushd /root/sdk/2.0.0+108156-165bbd8a64
  source "/root/sdk/2.0.0+108156-165bbd8a64/enable.sh"
popd

check_file_exist "/root/sdk/2.0.0+108156-165bbd8a64/enable.sh"
pushd /root/sdk/2.0.0+108156-165bbd8a64
  source "/root/sdk/2.0.0+108156-165bbd8a64/enable.sh"
popd

# set +ex
EOF
}

function _modify_setting_json(){
  local file=$1
  local total_line=$(wc -l ${file} | awk -F' ' '{print $1}')
  local last_line=$((total_line - 1))

  local a=0
  cat ${file} | while read LINE
  do
    echo $LINE
  done

}

function _add_to_setting_json(){
  local workspace=$1
  if [[ ! -f "$workspace/.vscode/settings.json" ]]; then
    cat <<EOF > "$workspace/.vscode/settings.json"
{
    "python.envFile": "\${workspaceFolder}/.vscode/.ipu.env",
    // this is for running bash script before initiating internal terminal
    "terminal.integrated.shellArgs.linux": ["-c", "source .vscode/terminal.env.sh; zsh"],
}
EOF
  else
    sed -i '1a "terminal.integrated.shellArgs.linux": ["-c", "source .vscode/terminal.env.sh; zsh"],",' "$workspace/.vscode/settings.json"
    sed -i '1a // this is for running bash script before initiating internal terminal",' "$workspace/.vscode/settings.json"
    sed -i '1a "python.envFile": "${workspaceFolder}/.vscode/.ipu.env",' "$workspace/.vscode/settings.json"
  fi
}


while [ "$1" != "" ]; do
    case $1 in
        -p | --project)          shift
                                _project=$1
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

if [[ ${_project} != "" ]]; then
  if [[ ${_project} == /* ]]; then
    _project=${_project}
  else
    _project="${PWD}/${_project}"
  fi
else
  _project="${PWD}"
fi

if [[ -d "${_project}" ]]; then
  if [[ ! -d "${_project}/.vscode" ]];then
    mkdir -p "${_project}/.vscode"
  fi
else
  printf "\e[93m%s does not exsists.\n\e[0m" ${_project}
  exit 0
fi



# set -ex 

gen_envfile ${_project}
gen_terminial_init_script ${_project}
_add_to_setting_json ${_project}

# set +ex