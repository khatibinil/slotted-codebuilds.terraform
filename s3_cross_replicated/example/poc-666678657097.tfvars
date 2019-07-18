#--------------------------------------------------------------
# General
#--------------------------------------------------------------

# For POC purposes, username can be used for app_abbreviation. app_abbreviation prefixes resources for uniqueness.
app_abbreviation = ""
use_case = "poc"
# Using "All" as the CMDB code for global POCs is fine. If application-specific, please use the application one.
app_cmdb_code = "All"
environment = "sbx"

# Buckets to create. Region abbreviation will be appended for uniqueness in an environment, but 
# environment is NOT mixed in and should be set in the tfvars file to ensure uniqueness *across* environments.
bucket_prefixes = [
  "REPLACEME",
  "REPLACEME2"
]
