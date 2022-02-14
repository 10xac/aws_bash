import boto3
import sys
from pynvml import nvmlDeviceGetPowerUsage, NVMLError, nvmlDeviceGetTemperature, NVML_TEMPERATURE_GPU
from pynvml import nvmlDeviceGetUtilizationRates, nvmlInit, nvmlDeviceGetCount
from pynvml import nvmlDeviceGetHandleByIndex, nvmlShutdown
from pynvml import *
from datetime import datetime
from time import sleep

if len(sys.argv) == 2:
    group = sys.argv[1]
else:
    print("Please enter a commandline arguement as shown below: \n")
    print("usage: gpu_monitor.py <instance name> e.g gpu_monitor.py group_1")
    exit()

# CHOOSE REGION ####
EC2_REGION = 'eu-west-1'

# CHOOSE NAMESPACE PARMETERS HERE###
my_NameSpace = f'{group} GPU Monitoring'

# CHOOSE PUSH INTERVAL ####
sleep_interval = 5

# CHOOSE STORAGE RESOLUTION (BETWEEN 1-60) ####
store_reso = 60

instances = {
    "b4_group_6": {
        "INSTANCE_ID": 'i-0f3acf934eda07a94',
        "IMAGE_ID": 'ami-02b4e72b17337d6c1',
        "INSTANCE_TYPE": 'g4dn.2xlarge'
    },
    "b4_group_5": {
        "INSTANCE_ID": 'i-0a6177c7f81557259',
        "IMAGE_ID": 'ami-02b4e72b17337d6c1',
        "INSTANCE_TYPE": 'g4dn.2xlarge'
    },
    "b4_group_4": {
        "INSTANCE_ID": 'i-0c9061822a102be57',
        "IMAGE_ID": 'ami-02b4e72b17337d6c1',
        "INSTANCE_TYPE": 'g4dn.2xlarge'
    },
    "b4_group_3": {
        "INSTANCE_ID": 'i-02eee31eb0fbddd4b',
        "IMAGE_ID": 'ami-02b4e72b17337d6c1',
        "INSTANCE_TYPE": 'g4dn.2xlarge'
    },
    "b4_group_2": {
        "INSTANCE_ID": 'i-0ccd4223467d3e195',
        "IMAGE_ID": 'ami-02b4e72b17337d6c1',
        "INSTANCE_TYPE": 'g4dn.2xlarge'
    },
    "b4_group_1": {
        "INSTANCE_ID": 'i-0d6cc4864a9935af1',
        "IMAGE_ID": 'ami-02b4e72b17337d6c1',
        "INSTANCE_TYPE": 'g4dn.2xlarge'
    }
}

# Instance information
# BASE_URL = 'http://34.240.226.234/latest/meta-data/'
INSTANCE_ID = instances[group]['INSTANCE_ID']
IMAGE_ID = instances[group]['IMAGE_ID']
INSTANCE_TYPE = instances[group]['INSTANCE_TYPE']
# INSTANCE_AZ = urlopen(BASE_URL + 'placement/availability-zone').read()
# EC2_REGION = INSTANCE_AZ[:-1]

TIMESTAMP = datetime.now().strftime('%Y-%m-%dT%H')
TMP_FILE = '/tmp/GPU_TEMP'
TMP_FILE_SAVED = TMP_FILE + TIMESTAMP

# Create CloudWatch client
cloudwatch = boto3.client('cloudwatch', region_name=EC2_REGION)

# Flag to push to CloudWatch
PUSH_TO_CW = True

def getPowerDraw(handle):
    try:
        powDraw = nvmlDeviceGetPowerUsage(handle) / 1000.0
        powDrawStr = '%.2f' % powDraw
    except NVMLError as err:
        powDrawStr = handleError(err)
        PUSH_TO_CW = False
    return powDrawStr

def getTemp(handle):
    try:
        temp = str(nvmlDeviceGetTemperature(handle, NVML_TEMPERATURE_GPU))
    except NVMLError as err:
        temp = handleError(err)
        PUSH_TO_CW = False
    return temp

def getUtilization(handle):
    try:
        util = nvmlDeviceGetUtilizationRates(handle)
        gpu_util = str(util.gpu)
        mem_util = str(util.memory)
    except NVMLError as err:
        error = handleError(err)
        gpu_util = error
        mem_util = error
        PUSH_TO_CW = False
    return util, gpu_util, mem_util

def logResults(i, util, gpu_util, mem_util, powDrawStr, temp):
    try:
        gpu_logs = open(TMP_FILE_SAVED, 'a+')
        writeString = str(i) + ',' + gpu_util + ',' + mem_util + ',' + powDrawStr + ',' + temp + '\n'
        gpu_logs.write(writeString)
    except:
        print("Error writing to file ", gpu_logs)
    finally:
        gpu_logs.close()
        
    if (PUSH_TO_CW):
        MY_DIMENSIONS = [
            {
                'Name': 'InstanceId',
                'Value': INSTANCE_ID
            },
            {
                'Name': 'ImageId',
                'Value': IMAGE_ID
            },
            {
                'Name': 'InstanceType',
                'Value': INSTANCE_TYPE
            },
            {
                'Name': 'GPUNumber',
                'Value': str(i)
            }
        ]
        cloudwatch.put_metric_data(
            MetricData=[
                {
                    'MetricName': 'GPU Usage',
                    'Dimensions': MY_DIMENSIONS,
                    'Unit': 'Percent',
                    'StorageResolution': store_reso,
                    'Value': util.gpu
                },
                {
                    'MetricName': 'Memory Usage',
                    'Dimensions': MY_DIMENSIONS,
                    'Unit': 'Percent',
                    'StorageResolution': store_reso,
                    'Value': util.memory
                },
                {
                    'MetricName': 'Power Usage (Watts)',
                    'Dimensions': MY_DIMENSIONS,
                    'Unit': 'None',
                    'StorageResolution': store_reso,
                    'Value': float(powDrawStr)
                },
                {
                    'MetricName': 'Temperature (C)',
                    'Dimensions': MY_DIMENSIONS,
                    'Unit': 'None',
                    'StorageResolution': store_reso,
                    'Value': int(temp)
                },
            ],
            Namespace=my_NameSpace
        )


nvmlInit()
deviceCount = nvmlDeviceGetCount()

def main():
    try:
        while True:
            PUSH_TO_CW = True
            # Find the metrics for each GPU on instance
            for i in range(deviceCount):
                handle = nvmlDeviceGetHandleByIndex(i)

                powDrawStr = getPowerDraw(handle)
                temp = getTemp(handle)
                util, gpu_util, mem_util = getUtilization(handle)
                print(util, gpu_util, mem_util)
                logResults(i, util, gpu_util, mem_util, powDrawStr, temp)

            sleep(sleep_interval)

    finally:
        nvmlShutdown()

if __name__ == '__main__':
    main()
