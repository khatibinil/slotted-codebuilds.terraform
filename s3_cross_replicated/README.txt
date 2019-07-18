This S3 replicated module sets up bucket replication of KMS-encrypted objects, creating unique
KMS keys and requiring KMS encryption for all source and destination objects.

The AWS CRR-KMS feature is currently pre-release as of 11/2017, and requires special configuration of the AWS
commandline to enable. See Ruben Rodriguez or Mark Olson for the necessary configuration instructions
and enabled accounts. This module generates the necessary JSON files for configuration as well as
outputing the CLI commands, but the CLI requires pre-configuration. Once released, the CLI step will be
automated as well.

This module is designed for 2-way replication between regions. Buckets are set up in 2 regions, and both
buckets replicate to each other to ensure data is available in both regions for HA. NOTE: Deletes are
replicated in both direction, irrespective of where the object was originally uploaded. Versioning should
be considered accordingly.

If data resiliency is required for customer data, the s3_resilient module should be used instead.

The module takes a list of bucket prefixes as input, and sets up the 2 buckets with the given prefixes + a region
abbreviation suffix. In the default case (as shown in the examples folder), buckets are created in us-west-2
and us-east-1 with suffixes -w2 and -e1 respectively.

NOTE!: Only adding to the end of the bucket prefixes is supported without great care to Terraform state editing.

There are sensible defaults set for version retention and lifecycle policies, but can be adjusted according
to business requirements.