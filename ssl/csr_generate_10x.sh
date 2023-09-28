#--------------------------------------------------------#
###-------- Certificate setup -----##
##------------------------------------------------------#

#Let’s create a key pair and import it as an ACM certificate.
#We will associate this certificate with the ALB.
#The same key and certificate will be used to enable TLS encryption in the Envoy proxy.

curdir=`pwd`
certdir=data/csr
mkdir -p $certdir
cd $certdir

##Create the config
cat <<EOF > castore.cfg
[ req ]
default_bits = 2048
default_keyfile = my-aws-private.key
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no
[ req_distinguished_name ]
C = US
ST = California
L = Santa Clara
O = 10 Academy  ##Name
OU = 10 Academy ##Division
CN= *.10academy.org ## Use your domain
emailAddress = yabebal@10academy.org ## Use your email address
[v3_ca]
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always,issuer:always
basicConstraints = CA:true
[v3_req]
## Extensions to add to a certificate request
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
EOF

#Use OpenSSL to create the certificate signing authority and then generate the private key and certificate using it.
openssl genrsa -out castore.key 2048
openssl req -x509 -new -nodes -key castore.key -days 3650 -config castore.cfg -out castore.pem

openssl genrsa -out my-aws-private.key 2048
openssl req -new -key my-aws-private.key -out my-aws.csr -config castore.cfg
openssl x509 -req -in my-aws.csr -CA castore.pem -CAkey castore.key -CAcreateserial  -out my-aws-public.crt -days 365

ls
