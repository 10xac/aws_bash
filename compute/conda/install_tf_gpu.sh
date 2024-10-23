conda create --name tfgpu python=3.9
source activate tfgpu

conda install pip  -y
pip install --upgrade pip

#
conda install -c conda-forge cudatoolkit=11.2 cudnn=8.1.0 -y

mkdir -p $CONDA_PREFIX/etc/conda/activate.d
echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CONDA_PREFIX/lib/' > $CONDA_PREFIX/etc/conda/activate.d/env_vars.sh


cat <<EOF /tmp/requirements.txt
################################################################
# Basic packages used in many of the tutorials.

numpy
scipy
jupyter
matplotlib
Pillow
scikit-learn

################################################################
# TensorFlow v.2.1 and above include both CPU and GPU versions.

tensorflow
EOF

pip3 install -r /tmp/requirements.txt

#https://www.drdataking.com/post/using-tensorflow-with-gpu-within-rmarkdown/
EOF <<EOF test_gpu.sh
import tensorflow as tf

print(tf.config.list_physical_devices('GPU'))

gpus = tf.config.list_physical_devices(device_type = 'GPU')
tf.config.experimental.set_memory_growth(gpus[0], True)

EOF

python3 test_gpu.sh 
