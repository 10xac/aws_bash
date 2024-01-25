import boto3
import paramiko
import time
from . import secret

# AWS credentials and region
aws_region = 'us-east-1'  # Change this to your desired region
profile_name =  "ustenac"


# Initialize AWS EC2 and CloudWatch clients
# aws_access_key = 'YOUR_ACCESS_KEY'
# aws_secret_key = 'YOUR_SECRET_KEY'
# ec2_client = boto3.client('ec2', aws_access_key_id=aws_access_key, aws_secret_access_key=aws_secret_key, region_name=aws_region)
# cloudwatch_client = boto3.client('cloudwatch', aws_access_key_id=aws_access_key, aws_secret_access_key=aws_secret_key, region_name=aws_region)

kwargs = {'region_name': aws_region}
if secret.is_running_in_ec2_instance():
    print('********We are running inside EC2 instance*********')
else:
    kwargs['profile_name'] = profile_name
    print('*******We are running in NON-EC2 machine**************')

    
print(f'Using boto3.Session kwargs: {kwargs}')
    
session = boto3.Session(**kwargs)
ec2_client = session.client('ec2', region_name=aws_region)
cloudwatch_client = session.client('cloudwatch', region_name=aws_region)


# Function to check SSH connections
def check_ssh_connections(instance_id, ssh_username='ubuntu', ssh_pkey='~/.ssh/itrain-team-useast1.pem'):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        ssh.connect(instance_id, username=ssh_username, key_filename=ssh_key)
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command("netstat -tnpa | grep ':22 ' | wc -l")
        ssh_connections = int(ssh_stdout.read().decode().strip())
        ssh.close()
        return ssh_connections
    except Exception as e:
        print(f"Error checking SSH connections: {e}")
        return -1

# Function to check CPU utilization
def check_cpu_utilization(instance_id, since=300, interval=60, stat="Max"): #'Average'
    '''
    since - time in seconds since when we are getting cpu utilisation 
    interval - sampling interval in seconds
    stat - how cpu utilisation is computed
    '''
    
    response = cloudwatch_client.get_metric_statistics(
        Namespace='AWS/EC2',
        MetricName='CPUUtilization',
        Dimensions=[
            {
                'Name': 'InstanceId',
                'Value': instance_id
            },
        ],
        StartTime=time.time() - since,  # 5 minutes ago
        EndTime=time.time(),
        Period=interval,  # 1-minute intervals
        Statistics=[stat]
    )

    if 'Datapoints' in response:
        datapoints = response['Datapoints']
        if len(datapoints) > 0:
            average_cpu_utilization = datapoints[-1]['Average']
            return average_cpu_utilization
    return -1

def list_running_ec2_instance_ids_by_name(name_tag):

    if isinstance(name_tag, str):
        tag_names = [name_tag]
    elif isinstance(name_tag, list):
        tag_names = name_tag
    else:
        print(f'name_tag={name_tag} is not valid. It must be str or list')
        return []
    
    try:
        # Use the describe_instances method to retrieve information about EC2 instances
        response = ec2_client.describe_instances(Filters=[
            {'Name': 'instance-state-name', 'Values': ['running']},
            {'Name': 'tag:Name', 'Values': [name_tag]}
        ])

        # Extract and print the instance IDs
        running_instance_ids = [instance['InstanceId'] for reservation in response['Reservations'] for instance in reservation['Instances']]
        
        return running_instance_ids
    except Exception as e:
        print(f"Error listing running EC2 instances by name tag: {e}")
        return []
    
def list_running_ec2_instance_ids():

    try:
        # Use the describe_instances method to retrieve information about EC2 instances
        response = ec2_client.describe_instances(Filters=[{'Name': 'instance-state-name', 'Values': ['running']}])

        # Extract and print the instance IDs
        running_instance_ids = [instance['InstanceId'] for reservation in response['Reservations'] for instance in reservation['Instances']]
        
        return running_instance_ids
    except Exception as e:
        print(f"Error listing running EC2 instances: {e}")
        return []


def check_and_start_ec2_instance(instance_ids=[], name_tags=""):

    # Handle input cases
    if len(instance_ids)==0 and len(name_tags)>0:
        print(f'-------getting instances with name_tags={name_tags} ...')
        instance_ids = list_running_ec2_instance_ids_by_name(name_tags)
        
    if len(instance_ids)==0:
        print('No instances found to start')
        return
    else:
        if isinstance(instance_ids, str)
            instance_ids = [instance_ids]

    print(f'-------Instances to Start: ')
    print(instance_ids)
            
    try:
        for instance_id in instance_ids:
            # Describe the instance to check its current state
            response = ec2_client.describe_instances(InstanceIds=[instance_id])

            # Extract the state of the instance (it can be 'running', 'stopped', etc.)
            instance_state = response['Reservations'][0]['Instances'][0]['State']['Name']

            if instance_state == 'stopped':
                # The instance is stopped, so we can start it
                ec2_client.start_instances(InstanceIds=[instance_id])
                print(f"Starting EC2 instance with ID: {instance_id}")
            elif instance_state == 'running':
                print(f"EC2 instance with ID: {instance_id} is already running.")
            else:
                print(f"EC2 instance with ID: {instance_id} is in an unexpected state: {instance_state}")
    except Exception as e:
        print(f"Error checking and starting EC2 instance: {e}")

    

    
if __name__ == "__main__":    
    # Main loop
    while True:

        name_tags = [f"group{x}" for x in range(1,7)]
        print(f'-------getting instances with name_tags={name_tags} ...')
        instance_ids_list = list_running_ec2_instance_ids_by_name(name_tags)
        print(f'-------found the following instances matching filter: ')
        print(instance_ids_list)

        if len(instance_ids_list)==0:
            print('==== No EC2 instances found ====')
            break

        for instance_id in instance_ids_list:
            ssh_connections = check_ssh_connections(instance_id)
            cpu_utilization = check_cpu_utilization(instance_id, since=600)  #600 secons means 10mins

            if ssh_connections == 0 or (cpu_utilization >= 0 and cpu_utilization < 1):
                print(f"Stopping instance {instance_id} due to conditions met.")
                ec2_client.stop_instances(InstanceIds=[instance_id])    

            print(f"Stat for {instance_id} - SSH Connections: {ssh_connections}, CPU Utilization: {cpu_utilization}%")

        time.sleep(60)  # Check every minute
