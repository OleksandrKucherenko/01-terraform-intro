# Developer Environment

## AWS Cloud Access

1. Create e-mail alias for developer or use `name+suffix@domain.com` or `3rd level sub-domain` syntax.
   1. 3rd level example: `alexk@terraform.artfulbits.se`
   2. Suffix example: `alexk+developer@artfulbits.se`
2. Go To https://aws.amazon.com/ and Press `Create an AWS account`
   1. Create secure password, use `LastPass` generate password tool
   2. AWS account name: `sandbox`
3. Create ghost card in Klarna app and use it for passing the registration process
4. Login into admin console, select in top right corner region: `Stockholm` / `eu-north-1`
5. This is a `ROOT` user. Enable and configure for it MFA. Use [Google Authenticator](https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2&hl=en). _During registration you should enter two codes, and after that registration will be accomplished._
6. https://console.aws.amazon.com/iam/home?#/security_credentials
   1. Press `Access keys` and create a new key:
   2. Access Key ID: `AKIAJHAPX47E246VYSMA`
   3. Secret Access Key: `JnXXw0ybjeUsywPoS4/v2n3mVK920v1TvYNK3BNc`

_Just FYI: used in documentation keys and IDs are fake or already replaced by new versions._

## Developer Tools

```bash
brew install bash       # bash 5.0
brew install awscli     # AWS CLI
brew install terraform  # terraform tool

```

### Upgrade/Extras

* [AWS CLI updates](https://docs.aws.amazon.com/cli/latest/userguide/install-macos.html)
    ```bash
    pip3 install awscli --upgrade --user
    ```

* [Terraform Docs](https://github.com/segmentio/terraform-docs)
    ```bash
    brew install terraform-docs
    ```

## Configuring AWS CLI

```bash
aws configure --profile terraform

# AWS Access Key ID [None]: AKIAJHAPX47E246VYSMA
# AWS Secret Access Key [None]: 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
# Default region name [None]: eu-north-1
# Default output format [None]: json
```

[how to confirm?](#confirm-root-user-configuration)

## Create Terraform User

For creating a special user please use script: `scripts/00_create-iam-user-for-terraform.sh`

```bash
scripts/00_create-iam-user-for-terraform.sh

# [-/-] creating adiministrators group...
# {
#     "Group": {
#         "Path": "/",
#         "GroupName": "gr_admins_terraform",
#         "GroupId": "AGPAQCFC533KFCB7PJZPQ",
#         "Arn": "arn:aws:iam::004636663508:group/gr_admins_terraform",
#         "CreateDate": "2019-06-07T09:24:10Z"
#     }
# }
# [-/-] creating terraform developer user...
# {
#     "User": {
#         "Path": "/",
#         "UserName": "terraform",
#         "UserId": "AIDAQCFC533KM7L2PDZMN",
#         "Arn": "arn:aws:iam::004636663508:user/terraform",
#         "CreateDate": "2019-06-07T09:24:12Z"
#     }
# }
# [-/-] configuring CLI access for new user...
# {
#     "LoginProfile": {
#         "UserName": "terraform",
#         "CreateDate": "2019-06-07T09:24:14Z",
#         "PasswordResetRequired": false
#     }
# }
# {
#     "AccessKey": {
#         "UserName": "terraform",
#         "AccessKeyId": "{KEY_ID}",
#         "Status": "Active",
#         "SecretAccessKey": "{SECRET}",
#         "CreateDate": "2019-06-07T09:24:15Z"
#     }
# }
# [-/-] configuring local AWS CLI...
# [-/-] composed credential properties file: ./keys/terraform.user.credentials.properties
# [-/-] All done!

# Hint (drop ROOT user access key):
#   aws iam delete-access-key --profile terraform --access-key-id=AKIAJHAPX47E246VYSMA
```

The last security step, execute the hint line:

```bash
aws iam delete-access-key --profile terraform --access-key-id=AKIAJHAPX47E246VYSMA
```

_Just FYI: its a fake key-id and it will ve different for each developer._

### Create Remote configuration S3 bucket

```bash
scripts/01_create-s3-remote-config.sh
```

Now your AWS account properly initialized.
You can start using `terraform` for development.

All other configurations of the infrastructure should happens via terraform scripts.

## What we are Building?

### Visual Overview

This is what we will build in next tutorial steps:

![3D Highly Scalable Web Application Architecture](_documentation_/3d-web-app-architecture.png)

### Highlights

* Two Zones Availability: Stockholm (eu-north-1) & USA (us-east-1)
* VPC (Virtual Private Cloud) - High level security
* Instance type is T3 _([more details about instance types](https://aws.amazon.com/ec2/instance-types/))_
* Master-Slave MySQL with cross-zone replication (Data lossless solution)
* Load balancing on front-end and back-end (Scaling and Fail tolerance)

#### What we keep in mind during development

* Secrets rotation:
  * Certificates
  * SSH keys
* Docker images for instances running with our code and configuration
* Backup/Restore solution for DB (S3 bucket with enabled versioning and uto-cleanup lifecycle rules)
* Version bumping (upgrade of instances with new version of docker image without stopping providing service)

## Troubleshooting

### Confirm ROOT user configuration

```bash
cat ~/.aws/config

# [profile terraform]
# region = eu-north-1
# output = json
```

Confirmation of credentials:

```bash
cat ~/.aws/credentials

# [terraform]
# aws_access_key_id = {KEY_ID}
# aws_secret_access_key = {SECRET}
```

### Limit Budget for AWS

Follow the instructions:
https://aws.amazon.com/getting-started/tutorials/control-your-costs-free-tier-budgets/

### Debug Terraform execution

```bash
# enable tracing (and maybe log to file)
export TF_LOG="TRACE"
# export TF_LOG_PATH="terraform.txt"

terraform init --reconfigure

# 2019/06/07 14:12:07 [INFO] Terraform version: 0.12.1
# 2019/06/07 14:12:07 [INFO] Go runtime version: go1.12.5
# 2019/06/07 14:12:07 [INFO] CLI args: []string{"/usr/local/bin/terraform", "init", "--reconfigure"}
# 2019/06/07 14:12:07 [DEBUG] Attempting to open CLI config file: /Users/oleksandr.kucherenko/.terraformrc
# 2019/06/07 14:12:07 [DEBUG] File doesn't exist, but doesn't need to. Ignoring.
# 2019/06/07 14:12:07 [INFO] CLI command args: []string{"init", "--reconfigure"}

# When done with tracing the problem
unset TF_LOG
```

### Initialize remote configuration

```bash
# Run first: scripts/01_create-s3-remote-config.sh
terraform init --backend-config=terraform.tfvars
terraform workspace new production
terraform workspace new sandbox
```

### AWS Best practices

- https://github.com/hashicorp/best-practices/blob/master/terraform/providers/aws/README.md
- https://cloudcraft.co/

### Code Styling

https://github.com/antonbabenko/pre-commit-terraform

### Oh-My-Zsh Theme/Prompt extension

A small extension that helps to detect current "workspace" used by terraform.

![Imgur](https://i.imgur.com/oLNvhI3.png)

Add those changes to your current ZSH theme (`~/.oh-my-zsh/themes/agnoster.zsh-theme` in my case) :

```bash
 239 + │ prompt_terraform() {
 240 + │     # dont show 'default' workspace in home dir
 241 + │     [[ "$PWD" == ~ ]] && return
 242 + │
 243 + │     # check if in terraform dir
 244 + │     if [[ -d .terraform ]]; then
 245 + │       workspace=$(terraform workspace show 2> /dev/null) || return
 246 + │       prompt_segment green black "🔩 ${workspace}"
 247 + │     fi
 248 + │ }
 249 + │
 250   │ ## Main prompt
 251   │ build_prompt() {
 252   │   RETVAL=$?
 253   │   prompt_status
 254   │   prompt_virtualenv
 255   │   prompt_aws
 256   │   prompt_context
 257 + │   prompt_terraform
 258   │   prompt_dir
 259   │   prompt_git
 260   │   prompt_bzr
 261   │   prompt_hg
 262   │   prompt_end
 263   │ }
```
