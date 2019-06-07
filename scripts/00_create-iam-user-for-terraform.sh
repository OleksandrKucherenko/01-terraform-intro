#!/usr/bin/env bash -e

# Print commands before executing them (useful for troubleshooting)
# set -x

function interruptMe {
  # print empty line, separate ^C from logs
  echo
}

function restoreEnv {
  echo
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

# extract aws_access_key_id from AWS credentials
cfg_parser "${HOME}/.aws/credentials"
cfg.section.terraform

# login, group and profile
LOGIN=terraform
GROUP=gr_admins_${LOGIN}
PROFILE=terraform
ARN_ADMIN=arn:aws:iam::aws:policy/AdministratorAccess

# create random password
PASS=`openssl rand -base64 32`

# create admins group
echo "[-/-] creating adiministrators group..."
aws iam create-group --group-name $GROUP --profile $PROFILE
aws iam attach-group-policy --group-name $GROUP --policy-arn $ARN_ADMIN --profile $PROFILE

# create first admin user for our project
echo "[-/-] creating terraform developer user..."
aws iam create-user --user-name $LOGIN --profile $PROFILE
aws iam add-user-to-group --user-name $LOGIN --group-name $GROUP --profile $PROFILE

# configure user access to the AWS
echo "[-/-] configuring CLI access for new user..."
aws iam create-login-profile --user-name $LOGIN --password "${PASS}" --no-password-reset-required --profile $PROFILE
aws iam create-access-key --user-name $LOGIN --profile $PROFILE | tee "keys/${LOGIN}.access-key.json"

# save access keys to a new AWS profile: terraformDev
echo "[-/-] configuring local AWS CLI..."
aws_new_key_id=$(cat "keys/${LOGIN}.access-key.json" | grep AccessKeyId | awk -F ':' -F '\"' '{print $4}')
aws_new_access_key=$(cat "keys/${LOGIN}.access-key.json" | grep SecretAccessKey | awk -F ':' -F '\"' '{print $4}')
echo "" >>~/.aws/credentials
echo "# generated at $(date +%Y-%m-%d_%H-%M-%S) / $(date +%s)" >>~/.aws/credentials
echo "[terraformDev]" >>~/.aws/credentials
echo "aws_access_key_id = ${aws_new_key_id}" >>~/.aws/credentials
echo "aws_secret_access_key = ${aws_new_access_key}" >>~/.aws/credentials

echo "" >>~/.aws/config 
echo "# generated at $(date +%Y-%m-%d_%H-%M-%S) / $(date +%s)" >>~/.aws/config
echo "[profile terraformDev]" >>~/.aws/config
echo "region = eu-north-1" >>~/.aws/config 
echo "output = json" >>~/.aws/config 

# compose properties file with configuration
export PROPS=keys/terraform.user.credentials.properties
echo "# generated at $(date +%Y-%m-%d_%H-%M-%S) / $(date +%s)" >$PROPS
echo "user.login=${LOGIN}" >>$PROPS
echo "user.password=${PASS}" >>$PROPS
echo "" >>$PROPS
echo "[-/-] composed credential properties file: ./${PROPS}"

# configure IAM passwords policy with a new profile/user
aws iam update-account-password-policy \
  --profile terraformDev \
  --minimum-password-length 32 \
  --require-numbers \
  --require-symbols \
  --require-uppercase-characters \
  --require-lowercase-characters \
  --max-password-age 7 \
  --hard-expiry

echo "[-/-] All done!"
echo
echo "Hint (drop ROOT user access key):"
echo "  aws iam delete-access-key --profile ${PROFILE} --access-key-id=${aws_access_key_id}"

# References:
#   https://blog.gruntwork.io/authenticating-to-aws-with-the-credentials-file-d16c0fbcbf9e
#   https://docs.aws.amazon.com/cli/latest/reference/iam/create-login-profile.html
#   https://docs.aws.amazon.com/cli/latest/reference/iam/create-access-key.html
#   https://github.com/kavehmz/aws-setup/tree/457a892667de3af7fc6806561415d0de935048ef
#   https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started_create-admin-group.html
#   https://gist.github.com/splaspood/1473761 - INI file parsing in BASH