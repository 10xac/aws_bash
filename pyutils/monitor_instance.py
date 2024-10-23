import os, sys
import json
import boto3
import paramiko
import time
import requests
from datetime import datetime


# AWS credentials and region
aws_region = 'us-east-1'  # Change this to your desired region
profile_name =  "ustenac"

# Example usage:
zone_id = 'Z034028834IXN0CQEMHZ9'  # 10academy.org
base_url = '10academy.org'  # Replace with the desired DNS record name

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
# Initialize the AWS Route 53 client
route53_client = session.client('route53', region_name=aws_region)

ssh_print_counter = 0


def create_or_update_a_record(prefix, ip_address):
    
    # Change group5 to g5
    if 'roup' in prefix:
        prefix = prefix.replace('roup', '')
        
    record_name = f"{prefix}.{base_url}"
    
    try:
        # Check if the A record already exists
        response = route53_client.list_resource_record_sets(HostedZoneId=zone_id)
        # for record_set in response['ResourceRecordSets']:
        #     if record_set['Name'] == record_name and record_set['Type'] == 'A':
        try:
            # A record with the same name exists; update it
            response = route53_client.change_resource_record_sets(
                HostedZoneId=zone_id,
                ChangeBatch={
                    'Changes': [
                        {
                            'Action': 'UPSERT',  # Use 'CREATE' to create a new record
                            'ResourceRecordSet': {
                                'Name': record_name,
                                'Type': 'A',
                                'TTL': 300,  # Time-to-live in seconds (adjust as needed)
                                'ResourceRecords': [{'Value': ip_address}],
                            }
                        }
                    ]
                }
            )
            print(f"Updated A record: {record_name} => {ip_address}")
            return True
        except Exception as e:
            # If the A record doesn't exist, create it
            response = route53_client.change_resource_record_sets(
                HostedZoneId=zone_id,
                ChangeBatch={
                    'Changes': [
                        {
                            'Action': 'CREATE',
                            'ResourceRecordSet': {
                                'Name': record_name,
                                'Type': 'A',
                                'TTL': 300,  # Time-to-live in seconds (adjust as needed)
                                'ResourceRecords': [{'Value': ip_address}],
                            }
                        }
                    ]
                }
            )
            print(f"Created A record: {record_name} => {ip_address}")
            return True

    except Exception as e:
        print(f"Error creating/updating A record: {e}")
        return False



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
        
        ssh.connect(instance_ip, 
                    username=ssh_username, 
                    key_filename=key_filename,
                    timeout=30,
                    auth_timeout=30,
                    banner_timeout=30)
        
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

def list_ec2_instance_ids_by_name_and_state(name_tag, state='running'):

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
            {'Name': 'instance-state-name', 'Values': [state]},
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

def convert_datetime_to_str(obj):
    if isinstance(obj, datetime):
        return obj.strftime('%Y-%m-%d %H:%M:%S')
    elif isinstance(obj, list):
        return [convert_datetime_to_str(item) for item in obj]
    elif isinstance(obj, dict):
        return {key: convert_datetime_to_str(value) for key, value in obj.items()}
    else:
        return obj
    
def flatten_dict(d, parent_key='', sep='_'):
    """
    Flatten a nested dictionary into a single-level dictionary.

    :param d: The input dictionary to be flattened.
    :param parent_key: The parent key for nested keys (used for recursion).
    :param sep: The separator to use between keys.
    :return: A flattened dictionary.
    """
    
    #print(f'flatten_dict() called with d={d}, parent_key={parent_key}, sep={sep}')
    
    if not isinstance(d, dict):
        if parent_key:
            return {parent_key: convert_datetime_to_str(d)}
        else:
            return {'key': convert_datetime_to_str(d)}
        
    items = []    
    for key, value in d.items():
        new_key = f"{parent_key}{sep}{key}" if parent_key else key
        if isinstance(value, dict):
            items.extend(flatten_dict(value, new_key, sep=sep).items())
        elif isinstance(value, list):            
            for v in value:
                items.extend(flatten_dict(v, new_key, sep=sep).items())
        else:
            items.append((new_key, convert_datetime_to_str(value)))
                        
    return dict(items)

def get_ec2_instance_state_by_tag(tag_name):

    try:
        # Use describe_instances to retrieve information about EC2 instances
        response = ec2_client.describe_instances(Filters=[{'Name': 'tag:Name', 'Values': [tag_name]}])

        # Check if instances with the specified tag were found
        if 'Reservations' in response and len(response['Reservations']) > 0:
            instance_details = []
            for instance in response['Reservations'][0]['Instances']:
                res = {}
                #res = flatten_dict(instance)
                #print('Obtained all details of an instance!')
                
                # Use describe_instance_status to get status check details
                instance_id = instance['InstanceId']
                
                status_response = ec2_client.describe_instance_status(InstanceIds=[instance_id])
                if 'InstanceStatuses' in status_response and len(status_response['InstanceStatuses']) > 0:
                    res = flatten_dict({'Status_Check': status_response['InstanceStatuses'][0]})
                    #res.update(res2)
                else:
                    res['Status_Check'] = "Unknown"  # No status check details found                
            
                instance_details.append(res)
                
            return instance_details
        else:
            print(f"No instances found with the tag name: {tag_name}")
            return {'status': 'not_found', 'message': f"No instances found with the tag name: {tag_name}"}

    except Exception as e:
        print(f"Error getting EC2 instance state by tag: {e}")
        return "Error"
    
def check_and_stop_ec2_instance(instance_ids=[], name_tags=""):
        
        # Handle input cases
        if len(instance_ids)==0 and len(name_tags)>0:
            print(f'-------getting instances with name_tags={name_tags} ...')
            instance_ids, public_ips, private_ips = list_ec2_instance_ids_by_name_and_state(name_tags, state='running')
            
        if len(instance_ids)==0:
            print('No instances found to stop')
            return
        
        if isinstance(instance_ids, str):
            instance_ids = [instance_ids]
    
        print(f'-------Instances to Stop: ')
        print(instance_ids)
        
        result_json = []
        
        try:
            for tag, instance_id in instance_ids.items():

                
                # Describe the instance to check its current state
                response = ec2_client.describe_instances(InstanceIds=[instance_id])
    
                # Extract the state of the instance (it can be 'running', 'stopped', etc.)
                instance_state = response['Reservations'][0]['Instances'][0]['State']['Name']
                
                iidInfo = {'instance_state': instance_state}
                
                if instance_state == 'running':
                    # The instance is running, so we can stop it
                    response = ec2_client.stop_instances(InstanceIds=[instance_id])                                    
                    iidInfo['status'] = 'stopped'                    
                    result_json.append(iidInfo)                    
                    print(f"Stopping EC2 instance with ID: {instance_id}")
                    
        except Exception as e:
            print(f"Error checking and stopping EC2 instance: {e}")
            result_json.append({'status': 'error', 'message': f"Error checking and stopping EC2 instance: {e}"})
            
        return result_json
                            
def check_and_start_ec2_instance(instance_ids=[], name_tags=""):

    # Handle input cases
    if len(instance_ids)==0 and len(name_tags)>0:
        print(f'-------getting instances with name_tags={name_tags} ...')
        instance_ids, public_ips, private_ips = list_ec2_instance_ids_by_name_and_state(name_tags, state='stopped')
        
    if len(instance_ids)==0:
        print('No instances found to start')
        return
    
    if isinstance(instance_ids, str):
        instance_ids = [instance_ids]

    print(f'-------Instances to Start: ')
    print(instance_ids)
    
    result_json = []
    
    try:
        for tag, instance_id in instance_ids.items():
            iidInfo = {}
            iidInfo['NameTag'] = tag
            iidInfo['instance_id'] = instance_id
            iidInfo['public_ip'] = public_ips.get(tag)
            iidInfo['private_ip'] = private_ips.get(tag)
            
            # Describe the instance to check its current state
            response = ec2_client.describe_instances(InstanceIds=[instance_id])

            # Extract the state of the instance (it can be 'running', 'stopped', etc.)
            instance_state = response['Reservations'][0]['Instances'][0]['State']['Name']
            
            iidInfo['instance_state'] = instance_state
            
            if instance_state == 'stopped':
                # The instance is stopped, so we can start it
                response = ec2_client.start_instances(InstanceIds=[instance_id])                
                
                # Get the public IP address of the instance
                
                ip_address = []
                iloop = 0
                while len(ip_address)==0:    
                    print(f'Waiting for public IP address ... iloop={iloop}')     
                    response = ec2_client.describe_instances(InstanceIds=[instance_id])           
                    ip_address = [instance['PublicIpAddress'] for reservation in response['Reservations'] 
                                        for instance in reservation['Instances']
                                        if 'PublicIpAddress' in instance
                                ]
                    if iloop>5:
                        break
                   
                    iloop += 1
                    time.sleep(5)
                   
                if len(ip_address)==0:
                    print(f"Failed to get public IP address for instance {instance_id}")
                else:
                    ip_address = ip_address[0]
                    if create_or_update_a_record(tag, ip_address):
                        print(f"A record creation/update request successfully sent with ip={ip_address}.")
                    else:
                        print("Failed to create/update the A record.")

                
                iidInfo['status'] = 'started'
                iidInfo['message'] = f"Starting EC2 instance with ID: {instance_id}"
                
                print(f"Starting EC2 instance with ID: {instance_id}")
            elif instance_state == 'running':
                iidInfo['status'] = 'running'
                iidInfo['message'] = f"EC2 instance with ID: {instance_id} is already running."
                print(f"EC2 instance with ID: {instance_id} is already running.")
            else:
                iidInfo['status'] = 'unexpected'
                iidInfo['message'] = f"EC2 instance with ID: {instance_id} is in an unexpected state: {instance_state}"
                print(f"EC2 instance with ID: {instance_id} is in an unexpected state: {instance_state}")
                
            result_json.append(iidInfo)
    except Exception as e:
        print(f"Error checking and starting EC2 instance: {e}")
        result_json.append({'status': 'error', 'message': f"Error checking and starting EC2 instance: {e}"})
        
    return result_json
                

if '__main__' == __name__:
    
     
    idleCounter = {}
      
    # Main loop 
    while True:

        print('-------------------------')
        name_tags = [f"group{x}" for x in range(1,7)]
        print(f'-------getting instances with name_tags={name_tags} ...')
        instance_ids, ip_addresses, private_ip_addresses = list_ec2_instance_ids_by_name_and_state(name_tags)
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
            print(f'==========Checking Idle State for Tag={name}===============')
            print()
            instance_id = instance_ids.get(name)
            instance_ip = ip_addresses.get(name)
            if not (instance_id and instance_ip):
                print(f'***WARN***: instance_name={name} has empyt id={instance_id} or ip={instance_ip}')                
                continue
            
            #print(f'Getting number of ssh connections for {name} instance..')
            ssh_connections = check_ssh_connections(instance_ip)

            #print(f'Getting cpu utilisation for {name} instance ..')
            cpu_utilization = check_cpu_utilization(instance_id, since=300)  #600 secons means 10mins
            
            print(f"Stat for {instance_id} - SSH Connections: {ssh_connections}, CPU Utilization: {cpu_utilization}%")            
            if ssh_connections < 2 and (cpu_utilization >= 0 and cpu_utilization < 1):
                if name in idleCounter:
                    idleCounter[name] += 1
                else:
                    idleCounter[name] = 1
                    
                if idleCounter[name] > 3:
                    print(f"Stopping instance {instance_id} as we detected idle state for 3 consecutive times")
                    ec2_client.stop_instances(InstanceIds=[instance_id])   
                    idleCounter[name] = 0
            else:
                idleCounter[name] = 0
                
            print(f'Idle Counter for tag_name={name}: {idleCounter[name]}')  
            print()



        time.sleep(300)  # Check every minute
