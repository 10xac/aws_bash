import sys, os
import time
from datetime import datetime
import json
import boto3
from pathlib import Path
from botocore.exceptions import ClientError
import logging
logger = logging.getLogger(__name__)

current_timestamp = datetime.now().strftime('%Y-%m-%dT%H:%M:%S')
region = 'eu-west-1'

def create_boto_client(profile='',service='ec2'):
    if profile:
        session = boto3.Session(profile_name=profile)
    else:
        session = boto3.Session(region_name=region)
            
    client = session.client(service)
    return client

def get_s3_log_path(instance_id, timestamp=current_timestamp, basename="cloud-init-output"):
    bucket = "all-tenx-system-logs"
    if instance_id:
        prefix = f"awslog/EC2Steps/{timestamp}/{basename}-{instance_id}.log"
    else:
        prefix = f"awslog/EC2Steps/{timestamp}/{basename}-" + "${instanceId}.log"        
    s3path = f's3://{bucket}/{prefix}'
    
    return bucket, prefix, s3path

def use_waiters_check_object_exists(bucket_name, key_name, delay=300, maxtry=12, profile=''):   
   s3_client = create_boto_client(profile=profile,service='s3')
   try:
      waiter = s3_client.get_waiter('object_exists')
      waiter.wait(Bucket=bucket_name, Key = key_name,
                  WaiterConfig={
                     'Delay': delay, 'MaxAttempts': maxtry})
      print('Object exists: ' + bucket_name +'/'+key_name)
   except ClientError as e:
      raise Exception( "boto3 client error in use_waiters_check_object_exists: " + e.__str__())
   except Exception as e:
      raise Exception( "Unexpected error in use_waiters_check_object_exists: " + e.__str__())
 
def create_ec2_instance(ec2params, logger=logger):
    '''
    Based on Boto3 documentation 
    https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2.html#EC2.Client.run_instances
    '''

    profile = ec2params.get('profile','')
    timestamp = ec2params.get('timestamp',current_timestamp)
    
    print('-'*88)

    print ("Creating  ec2 instances using the following parameters ...")
    print()
    print(json.dumps(ec2params, indent=4, sort_keys=True))
    print()

    if ec2params.get('UserData','')=='':
        print('UserData can not be empty - pleeas pass script to run when ec2 starts')
        return
    
    ec2_client = create_boto_client(profile=profile,service='ec2')

    #
    blockDeviceMappings = [
        {
            'DeviceName': ec2params.get('DeviceName','/dev/sda1'),
            'Ebs': {
                      'DeleteOnTermination': True,
                      'VolumeSize': ec2params.get('DiskSizeGB',20),
                      'VolumeType': 'gp2'
                }
        },
        ]

    #
    iamInstanceProfile = {
        'Name': ec2params.get('IamInstanceProfile','EC2DockerS3Role')
        }

    Tags = [
        {
            'ResourceType': 'instance',
            'Tags': [
            {
                'Key': 'Name',
                'Value': ec2params.get('Name','')
            },
                ]
        },
        {
            'ResourceType': 'volume',
            'Tags': [
                {
                    'Key': 'Name',
                    'Value': ec2params.get('Name','')
                },
                ]
        }
        ]
    
    response = ec2_client.run_instances(#cpu & memory
                                            MinCount=1,
                                            MaxCount=1,
                                            InstanceType=ec2params.get('InstanceType','t3.medium'),
                                            BlockDeviceMappings=blockDeviceMappings,
                                        #security & permissions
                                            IamInstanceProfile=iamInstanceProfile,
                                            SecurityGroupIds=ec2params.get('SecurityGroupIds',[]),
                                            SubnetId=ec2params.get('SubnetId',''),
                                        #
                                            KeyName=ec2params.get('KeyName',''),
                                            UserData=ec2params.get('UserData',''),
                                        #
                                            ImageId=ec2params.get('AMIId'),
                                            TagSpecifications=Tags,
                                            Monitoring={'Enabled': True}
                                        )

    

    if response['ResponseMetadata']['HTTPStatusCode'] == 200:
        instance_id = response['Instances'][0]['InstanceId']
        
        print(f'----------Instance is launched successfully with instance_id={instance_id}. Waiting for system_ok status ..')        
        ec2_client.get_waiter('system_status_ok').wait(
            Filters=[
                     {
                       "Name": "instance-status.status",
                       "Values": ['ok']
                     },
                     {
                       "Name": "system-status.status",
                       "Values": ['ok']
                     },
                   ],                     
            InstanceIds=[instance_id]
        )
        print('Success! instance:', instance_id, 'is created and it is running, and has OK status')
    else:
        print('Error! Failed to create instance!')
        raise Exception('Failed to create instance!')

    if ec2params.get('TerminateAtRunning',False):
        bucket, prefix, s3path = get_s3_log_path(instance_id, timestamp=timestamp)
        print(f'Waiting to terminate instance - monitoring presence of {s3path} in s3 ..')
        use_waiters_check_object_exists(bucket,
                                        prefix,
                                        delay=300,
                                        maxtry=12,
                                        profile=profile)

        print('Terminating instance:', instance_id, ' after achiving a Running state ..')        
        ec2_client.terminate_instances(
            InstanceIds=[instance_id]
            )
        
    print('-'*88)
    
    return instance_id
 
 
def create_security_groups(prefix, logger):

    try:
        ec2_resource = boto3.resource('ec2')
        default_vpc = list(ec2_resource.vpcs.filter(
            Filters=[{'Name': 'isDefault', 'Values': ['true']}]))[0]
        logger.info("Got default VPC %s.", default_vpc.id)
    except ClientError:
        logger.exception("Couldn't get VPCs.")
        raise
    except IndexError:
        logger.exception("No default VPC in the list.")
        raise

    groups = {'manager': None, 'worker': None}
    for group in groups.keys():
        try:
            groups[group] = default_vpc.create_security_group(
                GroupName=f'{prefix}-{group}', Description=f"EMR {group} group.")
            logger.info(
                "Created security group %s in VPC %s.",
                groups[group].id, default_vpc.id)
        except ClientError:
            logger.exception("Couldn't create security group.")
            raise

    return groups


def delete_security_groups(prefix_name, logger):
        
    try:

        ec2_resource = boto3.resource('ec2')
        sgs = list(ec2_resource.security_groups.all())

        sgs_to_delete = [sg for sg in sgs if sg.group_name.startswith(prefix_name)]

        for sg in sgs_to_delete:
            print('{} {}'.format(sg.id, sg.group_name))

        for sg in sgs_to_delete:
            logger.info('Revoking ingress {}'.format(sg.group_name))
            try:
                if sg.ip_permissions:
                    sg.revoke_ingress(IpPermissions=sg.ip_permissions)
            except ClientError:
                logger.exception("Couldn't revoke ingress to %s.", sg.group_name)
                raise

        max_tries = 20  
        while True:
            try:
                for sg in sgs_to_delete:
                    logger.info('Deleting group name {}'.format(sg.group_name))
                    sg.delete()
                break
            except ClientError as error:
                max_tries -= 1
                if max_tries > 0 and \
                        error.response['Error']['Code'] == 'DependencyViolation':
                     logger.warning(
                        "Attempt to delete security group got DependencyViolation. "
                        "Waiting for 60 seconds to let things propagate.")
                     time.sleep(60)
                else:
                    raise
        logger.info("Deleted security groups")                  
    except ClientError:
        logger.exception("Couldn't delete security groups with prefix %s.", prefix_name)
        raise

def main(args):

    name = args.name
    fuserdata = args.mainscript
    fbasicparams = args.basicparams
    terminate = args.terminate
    profile = args.profile
    timestamp = args.timestamp
    
    # target script that needs to be run from new instance
    script = '' 
    for fname in fuserdata.split(','):
        print('Adding main script: {fname.strip()} ')
        script += '\n ' + Path(fname.strip()).read_text() 

    # to be loaded in all instances
    if fbasicparams:
        basicparams = Path(fbasicparams).read_text()
    else:
        print('*********ERROR: basicparams file must not be empty*********')
        raise
    
    install_awscli = Path('utils/install_awscli.sh').read_text()
    get_home = Path('utils/get_home.sh').read_text()
    common_pkgs = Path('utils/install_common_packages.sh').read_text()

    # optional installs
    if args.docker:
        install_docker = Path('utils/install_docker.sh').read_text()
    else:
        install_docker = ""

    if args.selenium or args.all:
        chrome_selenium = Path('utils/install_chrome_selenium.sh').read_text()
    else:
        chrome_selenium = ""

   
    if profile in ['','default']:
        pelement=""
    else:
        pelement = '''[profile $profile] \n region = $region \n output = json \n'''

    
    export_instance_id = "export instanceId=$(curl http://169.254.169.254/latest/meta-data/instance-id) \n"
    export_timestamp = f'export timestamp={timestamp} \n'
    #
    log_to_s3 = ' \n'
    for f in ["cloud-init-output", "app"]:
        bucket, prefix, s3path = get_s3_log_path('${instanceId}', timestamp=args.timestamp, basename=f)
        fname = f"/var/log/{f}.log"
        log_to_s3 += f'\n echo "====> Writing {fname} to {s3path} ..." '
        log_to_s3 += f'\n if [ -f {fname} ]; then \n aws s3 cp {fname} {s3path} \n fi \n'


    #------ define userdata ----
    userdata = f'''
#!/bin/bash

{export_instance_id}
{basicparams}
{export_timestamp}

{get_home}
{common_pkgs}
{chrome_selenium}


#write aws config file
cat <<EOFF >  config
[default]
s3 =
   signature_version = s3v4
region = $region

{pelement}
EOFF

#copy aws config file 
mkdir -p $HOME/.aws $home/.aws
cp config $HOME/.aws 
cp config $home/.aws

{install_awscli}
{script}

# writing logs to s3
{log_to_s3}
'''

    print(userdata)
        
    ec2params = {
        "profile": profile,
        "TerminateAtRunning": terminate,
        "Name": name,
        "DeviceName": "/dev/sda1",
        "DiskSizeGB": 20,
        "IamInstanceProfile": "EC2DockerS3Role",
        "AMIId": args.amiid,
        "KeyName": "tech-ds-team",
        "InstanceType": args.instancetype,
        "VpcID": "vpc-0e670b1bc65c6423e",
        "SubnetId": "subnet-0a7731a4b7f3da8f8",
        "SecurityGroupIds": ["sg-0f75fbfd58b0c43a8"], 
        "UserData": userdata,
        "timestamp": timestamp
    }
    
        
    return create_ec2_instance(ec2params, logger)


if __name__ == "__main__":

    import argparse
    
    parser = argparse.ArgumentParser()
    parser.add_argument('name',type=str, help = "Name of Instance")    
    parser.add_argument('--profile',type=str, help = "Profile to use to create instance", default='')
    parser.add_argument('--terminate',action='store_true',
                            help = "Terminate Instance when User Data script finishes")        
    parser.add_argument('--mainscript',type=str, help = '',default='utils/clone_repo.sh')
    parser.add_argument('--basicparams',type=str, help = '',default='')
    parser.add_argument('--timestamp',type=str, help = '',default=current_timestamp)        
    parser.add_argument('--instancetype',type=str, help = "", default='t3.medium')

    parser.add_argument('--amiid',type=str, help = "", default='')
    parser.add_argument('--ubuntu',action='store_true')
    parser.add_argument('--docker',action='store_true')
    parser.add_argument('--selenium',action='store_true')
   
    
    parser.add_argument('--all',action='store_true')    
    
    #
    args = parser.parse_args()    

    if args.ubuntu:
        args.amiid="ami-0258eeb71ddf238b3"  #Ubuntu 21.10 sup[p
    else:
        args.amiid="ami-0c62045417a6d2199"  #amazon linux - does not support TLS V1.3            
    
    
    #call main function 
    main(args)
    

    
