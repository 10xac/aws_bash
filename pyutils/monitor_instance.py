import os, sys
import boto3
import paramiko
import time
import requests


# AWS credentials and region
aws_region = 'us-east-1'  # Change this to your desired region
profile_name =  "ustenac"

def is_running_in_ec2_instance():
    try:
        # Send an HTTP request to the EC2 instance metadata service
        response = requests.get("http://169.254.169.254/latest/meta-data/instance-id", timeout=2)
        
        # If the request is successful (status code 200), it's running inside an EC2 instance
        return response.status_code == 200
    except requests.exceptions.RequestException:
        # If an exception is raised, it's not running inside an EC2 instance
        return False


# Initialize AWS EC2 and CloudWatch clients
# aws_access_key = 'YOUR_ACCESS_KEY'
# aws_secret_key = 'YOUR_SECRET_KEY'
# ec2_client = boto3.client('ec2', aws_access_key_id=aws_access_key, aws_secret_access_key=aws_secret_key, region_name=aws_region)
# cloudwatch_client = boto3.client('cloudwatch', aws_access_key_id=aws_access_key, aws_secret_access_key=aws_secret_key, region_name=aws_region)

kwargs = {'region_name': aws_region}
if is_running_in_ec2_instance():
    print('********We are running inside EC2 instance*********')
else:
    kwargs['profile_name'] = profile_name
    print('*******We are running in NON-EC2 machine**************')

    
print(f'Using boto3.Session kwargs: {kwargs}')
    
session = boto3.Session(**kwargs)
ec2_client = session.client('ec2', region_name=aws_region)
cloudwatch_client = session.client('cloudwatch', region_name=aws_region)

ssh_print_counter = 0

# Function to check SSH connections
def check_ssh_connections(instance_ip, ssh_username='ubuntu', ssh_pkey='itrain-team-useast1.pem'):
    global ssh_print_counter
    
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    #ssh.load_system_host_keys()
    try:
        key_filename = f"{os.environ['HOME']}/.ssh/{ssh_pkey}"
        if ssh_print_counter<2:
            print(f'Using instance_ip={instance_ip}, ssh_username={ssh_username}, ssh_pkey={key_filename}')
            ssh_print_counter += 1
        
        ssh.connect(instance_ip, username=ssh_username, key_filename=key_filename)
        
        command = "netstat -tnpa | grep ':22 ' | awk -F ' ' '{print $5}' | awk '$1 !~ /^(0|:)/' | sort | uniq -c | wc -l"
        ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(command)
        
        ssh_connections = int(ssh_stdout.read().decode().strip())
        ssh.close()
        return ssh_connections
    except Exception as e:
        print(f"Error checking SSH connections: {e}")
        return -1

# Function to check CPU utilization
def check_cpu_utilization(instance_id, since=300, interval=60, stat="Maximum"): #'Average'
    '''
    since - time in seconds since when we are getting cpu utilisation 
    interval - sampling interval in seconds
    stat - how cpu utilisation is computed allowd values are SampleCount, Average, Sum, Minimum, Maximum
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
            average_cpu_utilization = datapoints[-1][stat]
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
            {'Name': 'tag:Name', 'Values': tag_names}
        ])


        # Extract ip addresses
        # Initialize a list to store IP addresses
        ip_addresses = {}
        private_ip_addresses = {}
        running_instance_ids = {}

        # Iterate through reservations and instances to extract IP addresses
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:

                # Get the instance name from the tags
                name = None
                for tag in instance.get('Tags', []):
                    if tag['Key'] == 'Name':
                        name = tag['Value']
                        break

                instance_id = instance['InstanceId']
                private_ip = instance.get('PrivateIpAddress')
                public_ip = instance.get('PublicIpAddress')

                if not name:
                    name = instance_id
                    
                running_instance_ids[name] = instance_id
                ip_addresses[name] = public_ip
                private_ip_addresses[name] = private_ip
                    
                # for network_interface in instance.get('NetworkInterfaces', []):
                #     # Extract the primary private IP address
                #     private_ip = network_interface.get('PrivateIpAddress')
                #     if private_ip:
                #         private_ip_addresses[instance['Name']] = private_ip

                #     # Extract public IP address (if available)
                #     public_ip = network_interface.get('Association', {}).get('PublicIp')
                #     if public_ip:
                #         ip_addresses[instance['Name']] = public_ip
                        
        return running_instance_ids, ip_addresses, private_ip_addresses
    
    except Exception as e:
        print(f"Error listing running EC2 instances by name tag: {e}")
        return [], [], []
    
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
    
    if isinstance(instance_ids, str):
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

    

    

if '__main__' == __name__:
    
    # Main loop    
    while True:

        print('-------------------------')
        name_tags = [f"group{x}" for x in range(1,7)]
        print(f'-------getting instances with name_tags={name_tags} ...')
        instance_ids, ip_addresses, private_ip_addresses = list_running_ec2_instance_ids_by_name(name_tags)
        print(f'-------found the following instances matching filter: ')
        print(instance_ids)
        print(ip_addresses)
        print()
        print('-------------------------')
        print()

        if len(instance_ids)==0:
            print('==== No EC2 instances found ====')
            break

        for name in name_tags:
            instance_id = instance_ids.get(name)
            instance_ip = ip_addresses.get(name)
            if not (instance_id and instance_ip):
                print(f'***WARN***: instance_name={name} has empyt id={instance_id} or ip={instance_ip}')                
                continue
            
            #print(f'Getting number of ssh connections for {name} instance..')
            ssh_connections = check_ssh_connections(instance_ip)

            #print(f'Getting cpu utilisation for {name} instance ..')
            cpu_utilization = check_cpu_utilization(instance_id, since=600)  #600 secons means 10mins
            
            print(f"Stat for {instance_id} - SSH Connections: {ssh_connections}, CPU Utilization: {cpu_utilization}%")            
            if ssh_connections < 2 or (cpu_utilization >= 0 and cpu_utilization < 1):
                print(f"Stopping instance {instance_id} due to conditions met.")
                #ec2_client.stop_instances(InstanceIds=[instance_id])    



        time.sleep(60)  # Check every minute
