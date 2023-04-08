import sys, os
import time
import glob
import json
import subprocess
import requests

import base64
import boto3
from botocore.exceptions import ClientError

region_name = "eu-west-1"

def init_aws_session():
    # Create a Secrets Manager client
    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )

    return client


def create_secret(secret_name, key, value):
    client = init_aws_session()

    # get original secrets
    res = client.update_secret(SecretId=secret_name, SecretString=json.dumps({key: value}))

    return res

def update_secret(secret_name, kv):
    client = init_aws_session()
    # get original secrets
    secret = get_secret(secret_name)
    secret.update(kv)
    res = client.update_secret(SecretId=secret_name, SecretString=json.dumps(secret))
    #print(secret)
    return res


def get_ssm_secret(secret_name):
    client = init_aws_session()

    # In this sample we only handle the specific exceptions for the 'GetSecretValue' API.
    # See https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
    # We rethrow the exception by default.

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        raise e
    else:
        # Decrypts secret using the associated KMS CMK.
        # Depending on whether the secret is a string or binary, one of these fields will be populated.
        if 'SecretString' in get_secret_value_response:
            secret = get_secret_value_response['SecretString']
        else:
            secret = base64.b64decode(get_secret_value_response['SecretBinary'])


    return secret

def config_from_string(sdata,fname=None):
    #check if /app exists     
    #if os.path.exists('/app'):
    #    rdir = '/app'

    data = json.loads(sdata)

    if fname:
        #make dir  
        if not os.path.dirname(fname):
            fname = f'~/.env/{fname}'        
        
        os.makedirs(os.path.dirname(fname),exist_ok=True)

    
        print(f'writing {fname} file ..')
        #dump it to json file       
        with open(fname, 'w') as outfile:
            json.dump(data, outfile)
        
    return data


def get_secret(pname, pvar=None,json=False,fname=''):
    
    authData = None
    if pvar is not None:
        if pvar in os.environ.keys():
            sdata = os.environ.get(pvar)
            authData = json.loads(sdata)
            return authData
    
    
    authData = config_from_string(get_ssm_secret(pname), fname=fname)
    #    
    return authData
    



def get_auth(ssmkey=None, envvar=None, fconfig=None):
  
    #pass through multiple alternatives to get credential
    if fconfig:            
        if os.path.exists(fconfig):
            try:
                print(f'reading auth from file: {fconfig} ..')        
                auth = json.load(open(fconfig))
                return auth
            except:
                print(f'reading {fconfig} failed!')

    if envvar:            
        if os.environ.get(envvar,''): 
            try:
                print(f'Getting {envvar} from environment ..')
                auth = config_from_string(os.environ.get(envvar,''),fname=fconfig)
                return auth
            except:
                print(f'getting enn variable {envvar} failed!')
                
    if ssmkey:
        try:
            print(f'Getting auth {ssmkey} from aws secret manager and saving it to {fconfig} ..')            
            auth = get_secret(ssmkey,fname=fconfig)
            return auth
        except Exception as e:
            print(f'getting secret {ssmkey} from aws ssm failed! ')
            #print(e)
            raise

    print('Crediential can not be obtained. Params are')
    print(f'ssmkey={ssmkey}, envvar={envvar}, fconfig={fconfig}')           
    raise

    return {}

if __name__ == "__main__":

    if len(sys.argv)>0:
        ssmkey=sys.argv[1]
        print(f'using passed ssmkey={ssmkey}')
    else:
        ssmkey='tenx/db/pjmatch'

    if '/' in ssmkey:
        suffix = os.path.basename(ssmkey)
    else:
        suffix = ssmkey

     
    fconfig = f'.env/{suffix}.json'
    
    print(f'reading {ssmkey} with envvar={suffix}, fconfig={fconfig}')

    
    path = os.path.dirname(os.path.realpath(__file__))
    path = os.path.dirname(path)
    dbauth = get_auth(ssmkey=ssmkey,
                      envvar=suffix,
                      fconfig=fconfig)
    print(dbauth)


	
