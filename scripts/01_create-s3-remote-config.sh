#!/usr/bin/env bash -e

# Print commands before executing them (useful for troubleshooting)
# set -x

function interruptMe {
  # print empty line, separate ^C from logs
  echo
}

function restoreEnv {
  echo
  rm -rf ./terraform.tfvars.ini
}

function cfg_parser {
    fixed_file=$(cat $1 | sed 's/ = /=/g')   # fix ' = ' to be '='
    IFS=$'\n' && ini=( $fixed_file )         # convert to line-array
    ini=( ${ini[*]//;*/} )                   # remove comments
    ini=( ${ini[*]/#[/\}$'\n'cfg.section.} ) # set section prefix
    ini=( ${ini[*]/%]/ \(} )                 # convert text2function (1)
    ini=( ${ini[*]/=/=\( } )                 # convert item to array
    ini=( ${ini[*]/%/ \)} )                  # close array parenthesis
    ini=( ${ini[*]/%\( \)/\(\) \{} )         # convert text2function (2)
    ini=( ${ini[*]/%\} \)/\}} )              # remove extra parenthesis
    ini[0]=''                                # remove first element
    ini[${#ini[*]} + 1]='}'                  # add the last brace
    eval "$(echo "${ini[*]}")"               # eval the result
}

# register cleanup method call on Interrupt and exit
trap restoreEnv EXIT
trap interruptMe SIGINT

# parse variables from main file. use trick for re-using the INI-file parser
echo "[defaults]" >./terraform.tfvars.ini
cat ./terraform.tfvars >>./terraform.tfvars.ini
cfg_parser "./terraform.tfvars.ini"

# load variables
cfg.section.defaults

# create bucket
aws s3api create-bucket \
    --acl private \
    --bucket $s3_config_bucket \
    --region $region \
    --create-bucket-configuration LocationConstraint=$region \
    --profile $profile

# enable versioning
aws s3api put-bucket-versioning \
    --bucket $s3_config_bucket \
    --versioning-configuration Status=Enabled \
    --profile $profile

# auto cleanup rule, delete older 7 days
aws s3api put-bucket-lifecycle \
  --bucket $s3_config_bucket \
  --lifecycle-configuration file://scripts/01_lifecycle.json \
  --profile $profile
