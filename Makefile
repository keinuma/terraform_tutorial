fmt:
	terraform fmt -recursive
plan:
	terraform plan -var environment=production root_domain_name=example.com
