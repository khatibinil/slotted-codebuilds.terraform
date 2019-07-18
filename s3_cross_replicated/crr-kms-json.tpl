{
  "Role": "${replicate_role}",
  "Rules": [
    {
      "Prefix": "",
      "Status": "Enabled",
      "SourceSelectionCriteria": {
        "SseKmsEncryptedObjects": {
          "Status": "Enabled"
        }
      },
      "Destination": {
        "Bucket": "${destination_bucket_arn}",
        "StorageClass": "STANDARD",
        "EncryptionConfiguration": {
          "ReplicaKmsKeyID": "${destination_kms_arn}"
        }
      },
      "ExistingObjectReplication": {
        "Status": "Enabled"
      }
    }
  ]
}
