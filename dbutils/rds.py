import os, sys
import pandas as pd
from datetime import datetime, timedelta
import time
import json
import numpy as np
import mysql.connector as mysql

from .secret import get_secret

default_db = 'algos_monitor'
default_table = 'campaign'

def dbconfig_from_string(sdata):
    rdir = '.'

    #env folder path
    rdir = f'{rdir}/.env'

    #make dir  
    os.makedirs(rdir,exist_ok=True)

    #db config file        
    fname = f'{rdir}/dbconfig.json'

    if isinstance(sdata,str):
        data = json.loads(sdata)
    else:
        data = sdata
        
    if  'username' in data.keys() and not 'user' in data.keys():
        data['user'] = data['username']

    print(f'writing {fname} file ..')

    #dump it to json file       
    with open(fname, 'w') as outfile:
        json.dump(data, outfile)

    return data

def get_dbauth(smname='dsmetadata/rds/mysql'):
    try:
        dbauth = json.load(open('.env/dbconfig.json'))
        #print('dbconfig loaded')
    except:
        if 'RDS_CONFIG' in os.environ.keys():
            dbauth = dbconfig_from_string(os.environ.get('RDS_CONFIG',''))
        else:
            try:
                dbauth = dbconfig_from_string(get_secret(smname))
            except:
                print(f'All methods to get RDS secret failed. Last tried to get secret from SSM using name={smname}')
                raise

    return dbauth

def get_connection(dbname = default_db):
    dbauth = get_dbauth()
    mydb = mysql.connect(host=dbauth['host'] ,
      user=dbauth['user'],
      password=dbauth['password'],
      database=dbname)
    return mydb


def db_execute(*args,many=False,tablename='',multi=True,**kwargs):
    table = kwargs.get('table',default_table)
    if not tablename:
        tablename = table
    
    connection = get_connection(**kwargs)
    cursor1 = connection.cursor()
    if many:
        cursor1.executemany(*args)        
    else:
        cursor1.execute(*args, multi=multi)
    #
    nrow = cursor1.rowcount
    if tablename:
        print(f"{nrow} records inserted successfully into {tablename} table")        
    
    connection.commit()
    cursor1.close()
    connection.close()
    return nrow

def db_execute_fetch(*args, many=False, tablename='', rdf=True, **kwargs):
    table = kwargs.get('table',default_table)
    if not tablename:
        tablename = table
    
    connection = get_connection(**kwargs)
    cursor1 = connection.cursor()
        
    if many:
        cursor1.executemany(*args)        
    else:
        cursor1.execute(*args)
        
    
    #get column names
    field_names = [i[0] for i in cursor1.description]   
    
    #get column values
    res = cursor1.fetchall()    
    
    #get row count and show info
    nrow = cursor1.rowcount
    if tablename:
        print(f"{nrow} recrods fetched from {tablename} table")        
    
    cursor1.close()
    connection.close()
    
    #return result
    if rdf:
        df = pd.DataFrame(res, columns=field_names)
        return df
    else:
        return res
    
def show_dbs():
    dbauth = get_dbauth()
    mydb = mysql.connect(host=dbauth['host'] ,
      user=dbauth['user'],
      password=dbauth['password'],buffered=True)

    cursor = mydb.cursor()
    cursor.execute("SHOW DATABASES")
    res = []
    for (databases) in cursor:
         res.append(databases[0])
    print(res)
    
    return res
    
    
def show_tables(**kwargs):
    q = 'SHOW TABLES'
    res = db_execute_fetch(q, **kwargs)
    for x in res:
        print(x) 
    return res

def get_table(q=None, table=default_table,rfilter={},**kwargs):    
    if q is None:
        q = f'''SELECT * 
                FROM {table} 
                '''
        if rfilter:
            prefix = 'WHERE'
            for k,v in rfilter.items():
                q += f'''
                {prefix} {table}.{cname} = "{cvalue}"
                '''
                prefix = 'AND'
                
    data = db_execute_fetch(q, rdf=True,**kwargs)
    return data

def execute_insert_query(row_as_dict, table_name, multi = False,**kwargs):
    connection = get_connection(**kwargs)
    cur = connection.cursor()
    if multi:
        sample_row_as_dict = row_as_dict[0]
    else:
        sample_row_as_dict = row_as_dict

    placeholder = ", ".join(["%s"] * len(sample_row_as_dict))
    stmt = "insert into `{table}` ({columns}) values ({values})".format(table=table_name,
                                                                         columns=",".join(sample_row_as_dict.keys()),
                                                                         values=placeholder)
    print('\n',stmt, '\n')
    if multi:
        row_as_tuple = [tuple(row.values()) for row in row_as_dict]
        cur.executemany(stmt, row_as_tuple)
    else:
        cur.execute(stmt, tuple(row_as_dict.values()))
    connection.commit()
    rows_affected = cur.rowcount
    print("{} rows affected for {} table".format(rows_affected, table_name))
    cur.close()
    connection.close()

    return rows_affected

def get_next_record_id(table_name = 'model', pkey = 'model_id',**kwargs):
    connection = get_connection(**kwargs)
    cur = connection.cursor()
    stmt = f"select {pkey} from {table_name} order by {pkey} desc limit 1";
    cur.execute(stmt)
    row_id = cur.fetchone()

    if row_id:
        row_id =row_id[0] + 1
    else:
        row_id = 1

    cur.close()
    connection.close()

    return row_id

def get_filtered_rows(table_name,rfilter={},**kwargs):
    '''
    Accepts table name and optional key/column filter as dict
    e.g. rfilter = {'algo_status':'Running'}
    and returns a list of dictionaries, each element containing 
    a single row in the data table_name entry.
    '''
    
    #apply where filter if passed
    where_filter = ""
    if rfilter:
        conds = []
        for k, v in rfilter.items():
            if isinstance(v,(list,tuple)):
                for vv in v:
                    if len(conds)>0:
                        op='OR'
                    else:
                        op=''
                    conds.append(f"{op} {k}='{vv}'")
            elif isinstance(v,str):
                if len(conds)>0:
                    op='AND'
                else:
                    op=''                
                conds.append(f"{op} {k}='{v}'")
        where_filter = "WHERE " + " ".join(conds)

    #for a query
    stmt = f"SELECT * from {table_name} {where_filter}"

    #excute query - returns list
    print('-------query statement-----')
    print(stmt)
 
    connection = get_connection(**kwargs)
    cur = connection.cursor(dictionary=True)   
    cur.execute(stmt)
    res = cur.fetchall()
        
    return res
    
def get_row_by_key(table_name, condition_columns, condition_value, return_multiple_rows = False):
    connection = get_connection()
    cur = connection.cursor(dictionary=True)
    stmt = f"SELECT * from {table_name} WHERE {condition_columns}='{condition_value}'"
    cur.execute(stmt)
    if return_multiple_rows:
        res = cur.fetchall()
    else:
        res = cur.fetchone()
    return res

def get_campaign_keys(astatus='Running',dbname=default_db):
    stmt = f'''
    SELECT 
        campaign.*, 
        model.algo_campaign_id, model.bidlist_id
    FROM campaign
    INNER JOIN model ON 
        campaign.algo_request_id = model.algo_request_id
    AND
        campaign.algo_status = '{astatus}'
    '''
    
    connection = get_connection(dbname=dbname)
    cur = connection.cursor(dictionary=True)
    cur.execute(stmt)
    res = cur.fetchall()
    
    return res

def get_kpi_weight_cid(self, cid):
    dbconn = get_connection()
    cur = dbconn.cursor(dictionary=True)
    ####join query missed...
    sql = f"select kpi_name, weight from kpi, campaign where campaign.campaign_id = {cid}"
    cur.execute(stmt)
    res = cur.fetchall()
    kpi = {}
    
    return kpi
    

def update_algo_status(campaign_id = None, algostatus = None):
    connection = get_connection()
    cur = connection.cursor()
    sql = f"update campaign set algo_status = '{algostatus}' where campaign_id = '{campaign_id}'"
    cur.execute(sql)
    connection.commit()
    if cur.rowcount > 0:
        uptodate = False
        print(cur.rowcount, "record(s) affected")
    cur.close()
    connection.close()
