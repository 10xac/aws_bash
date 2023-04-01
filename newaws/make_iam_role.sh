set -e

export AWS_PAGER=""

#-------------------------------------------------------------------------
#             process input arguments
#-------------------------------------------------------------------------

echo "Number passed arguments: $#"
if [ $# -gt 0 ]; then
   source $1
else
    echo "You must pass the following"
    echo "     1st argument - a configuration file: that contains key parameters"
    echo "     2nd argument - action: status or iplink  "
    exit 0
fi



profile_name=${profile_name:-$profile}
region=${region:-"eu-west-1"}


#-------------------------------------------------------------------------
#             define key variables
#-------------------------------------------------------------------------


create_ec2_dsde_role() {
    role_name=EC2DSDERole

    
    # res=$(aws iam create-role --role-name ${role_name} \
    #           --assume-role-policy-document file://logs/configs/ec2_trust_policy.json \
    #           --region $region --profile $profile_name)              

    # source logs/configs/aws_managed_policy_list.sh

    # for policyarn in "${ec2role[@]}"; do
    #     # To attach an AWS-managed policy to an IAM role with the AWS CLI, use the attach-role-policy command
    #     echo "attaching policy arn: $policyarn"
    #     res=$(aws iam attach-role-policy --policy-arn $policyarn --role-name ${role_name} \
    #               --region $region --profile $profile_name)
    # done

    #create instance profile and add the above role to it
    echo "creating instance profile: ${role_name}..."
    res=$(aws iam create-instance-profile --instance-profile-name $role_name \
              --region $region --profile $profile_name)

    echo "adding role to instance profile"
    aws iam add-role-to-instance-profile --instance-profile-name ${role_name} \
        --role-name ${role_name}   --region $region --profile $profile_name
    
}

create_ec2_dsde_role


exit

# function attach_policy_arn_to_role(){
#     # To attach a customer-managed policy to an IAM role
#     aws iam attach-role-policy --policy-arn YOUR_POLICY_ARN --role-name role-example --region $region --profile $profile_name

# }



# function put_inline_policy_to_role(){
#     # To attach an inline policy to an IAM role, we have to:
#     # 1. write and store the policy in a json file on the local file system
#     # 2. run the AWS CLI put-role-policy command
    
#     aws iam put-role-policy --role-name $rolename --policy-name $pname --policy-document file://$pfile --region $region --profile $profile_name

#     # verify 
#     #aws iam list-role-policies --role-name $rolename
# }


# function create_policy(){
# # Attach a Managed Policy to an IAM role with AWS CLI
    
#     # Managed policies are of 2 types:
#     # 1. AWS-managed policies - created and managed by AWS.
#     # 2. Customer-managed policies - created and managed by the user.
    
    
    
#     # To attach a customer-managed policy to an IAM role with the AWS CLI, we have to:
#     # 1. Create the managed policy and take note of the policy's ARN
#     # 2. Use the attach-role-policy command to attach the policy to the role
    
#     # To create the customer-managed policy
#     res=$(aws iam create-policy --policy-name read-s3 --policy-document file://read-s3.json --region $region --profile $profile_name)

#  }
