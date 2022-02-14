scp -r -i ~/.ssh/adludio-ml-box.pub 10.3.3.197:/var/log/dask-worker.log  /tmp/dask-worker_1.log
sudo mv /tmp/dask-worker_1.log /var/log
scp -r -i ~/.ssh/adludio-ml-box.pub 10.3.3.58:/var/log/dask-worker.log  /tmp/dask-worker_2.log
sudo mv /tmp/dask-worker_2.log /var/log

echo "------worker_1 log ------------"
tail -30 /var/log/dask-worker_1.log
echo "-------------------------------"
echo "------worker_1 log ------------"
tail -30 /var/log/dask-worker_2.log
