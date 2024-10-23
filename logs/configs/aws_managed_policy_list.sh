export AmazonEC2FullAccess=arn:aws:iam::aws:policy/AmazonEC2FullAccess
export AmazonS3FullAccess=arn:aws:iam::aws:policy/AmazonS3FullAccess
export CloudWatchFullAccess=arn:aws:iam::aws:policy/CloudWatchFullAccess
export AmazonSESFullAccess=arn:aws:iam::aws:policy/AmazonSESFullAccess
export AmazonECS_FullAccess=arn:aws:iam::aws:policy/AmazonECS_FullAccess
export AmazonEC2ContainerRegistryReadOnly=arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
export AmazonRDSFullAccess=arn:aws:iam::aws:policy/AmazonRDSFullAccess
export AWSGlueServiceRole=arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole
export AmazonAthenaFullAccess=arn:aws:iam::aws:policy/AmazonAthenaFullAccess
export AWSGlueSchemaRegistryFullAccess=arn:aws:iam::aws:policy/AWSGlueSchemaRegistryFullAccess
export SecretsManagerReadWrite=arn:aws:iam::aws:policy/SecretsManagerReadWrite

export ec2role=($SecretsManagerReadWrite $AmazonEC2FullAccess $AmazonS3FullAccess $AmazonRDSFullAccess \
                                         $AmazonAthenaFullAccess $AWSGlueServiceRole $AWSGlueSchemaRegistryFullAccess \
                                         $CloudWatchFullAccess $AmazonEC2ContainerRegistryReadOnly)
