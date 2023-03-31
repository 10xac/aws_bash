import os, sys

curdir = os.path.dirname(os.path.realpath(__file__))
cpath = os.path.dirname(curdir)
if not cpath in sys.path:
    sys.path.append(cpath)

import psycopg2
#import api
from secret import get_auth
from pandas.io import sql
import pandas as pd 

from datetime import datetime,date




    
    
def get_dbauth ():
    dbauth = get_auth(ssmkey="tenx/db/strapi",
                fconfig=f'{cpath}/.env/postdbconfig.json',
                envvar='rds_CONFIG',
                )
    if 'username' not in dbauth.keys():
        if 'user' in dbauth.keys():
            dbauth['username'] = dbauth['user']
    return dbauth
    
def db_connect( dbName='strapidev' ):

    dbauth = get_dbauth()
    
    try:
        db = psycopg2.connect(
            host=dbauth['host'],
            user=dbauth['username'],
            password=dbauth['password'],
            database = dbName             
        )
    except Exception as e :
            print ("Unable to connet to Mysqlpass",e)  

    return db
def db_execute_fetch(*args, many=False, tablename='', rdf=True, **kwargs):
    connection = db_connect( **kwargs)
    cursor1 = connection.cursor()
    
    if many:
        cursor1.executemany(*args)
    else:
        cursor1.execute(*args)
        
    # get column names
    field_names = [i[0] for i in cursor1.description]

    # get column values
    res = cursor1.fetchall()

    # get row count and show info
    nrow = cursor1.rowcount
    if tablename:
        print(f"{nrow} recrods fetched from {tablename} table")

    cursor1.close()
    connection.close()

    # return result
    if rdf:
        return pd.DataFrame(res, columns=field_names)
    else:
        return res

def showTables(q=None, **kwargs):
    if q is None:
        q = 'show tables'

    rdf = kwargs.pop('rdf', False)

    df = db_execute_fetch(q, rdf=False, **kwargs)

    print(df)

def select_from_table (tablename,dbName):
    # query = f"SELECT * from applicant_informations where batch= \'batch-5\'"
    query = f"select * from {tablename}" 
    
    # where test_score >= 20"
    df = db_execute_fetch(query, rdf=True, dbName=dbName)

    return df



def writeToReview(dbName, df):
    conn = db_connect(dbName)
    cur = conn.cursor()
    

    for index, elt in df.iterrows():
        # sqlQuery = """INSERT INTO review_responses(id,	content) VALUES(%s, %s)
                #    """
        data = (elt[3], elt[4])
        print(data)
        break
        # try:
        #     # Execute the SQL command
        #     cur.execute(sqlQuery, data)
        #     # Commit your changes in the database
        #     conn.commit()
        #     print("Data Inserted Successfully")
        # except Exception as e:
        #     print("Error: ", e)
        #     # Rollback in case there is any error
        #     conn.rollback()

def alter_table( **kwargs):
    connection = db_connect(**kwargs)
    cursor1 = connection.cursor()
    # '2nd_reviewer_id', '2nd_reviewer_accepted', ALTER TABLE Customers
    #  NOT NULL; varchar(10) NOT NULL
    # 3rd_reviewer_accepted boolean third_reviewer_id accepted  ALTER TABLE applicant_informations ADD id INT AUTO_INCREMENT PRIMARY KEY
    try:
        query= "ALTER TABLE batch_competencies ADD COLUMN Batch INT"
        cursor1.execute(query)
        print(f"Sucessfully altered")
    except Exception as e:
        print("Unable to alter",e)

def update_appli_with_reviewer(dbName='strapidev'):
    appliInfo = select_from_table("batch_competencies")
    print(appliInfo.columns)
    
    conn = db_connect(dbName)
    cur =conn.cursor()   
    for i, row in appliInfo.iterrows():
        
        id = row['id']
        print(id)
        
        
        
        
       
        batch = 4
        sqlQuery= f""" UPDATE batch_competencies SET batch = {batch} WHERE id = {id}
                    """ 
        
        try:
            # Execute the SQL command
            
            cur.execute(sqlQuery)
            # Commit your changes in the database
            conn.commit()
            print("Updated Successfully")
        except Exception as e:
            print("Error: ", e)
            # Rollback in case there is any error
            conn.rollback()       
  
def delete_tables (dbName= 'strapidev'):
    conn = db_connect(dbName)
    cur =conn.cursor() 
    ids = [1,2,3]
    for i in ids:
        sqlQuery= f""" DELETE FROM gmeets WHERE id = {i} 
                        """ 
            
        try:
            # Execute the SQL command
            
            cur.execute(sqlQuery)
            # Commit your changes in the database
            conn.commit()
            print("Deleted Successfully")
        except Exception as e:
            print("Error: ", e)
            # Rollback in case there is any error
            conn.rollback() 

if __name__ == "__main__":
# review_responses               
# review_responses_review_links       
# review_responses_reviewer_links  
    # tablename= 'grades_all_user_links'
    # tablename ='all_users'
    # df = select_from_table(tablename)
    # print(df)
    # tablename1 ='reviews_all_user_links'
    # df1 = select_from_table(tablename1)
    # print(df1)
    # delete_tables()
    tablename3 ='gmeets'
    df3 = select_from_table(tablename3, 'strapidev')
    print(df3)
    # alter_table()
    # update_appli_with_reviewer()
    # showTables(q= "SELECT * FROM review_responses;")