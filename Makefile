## Makefile (raiz do repositório)
```make
TF_DIR=nextcloud-aws-terraform

fmt:
	terraform -chdir=$(TF_DIR) fmt

validate:
	terraform -chdir=$(TF_DIR) validate

plan:
	terraform -chdir=$(TF_DIR) plan -var db_password=$$DB_PASSWORD

apply:
	terraform -chdir=$(TF_DIR) apply -auto-approve -var db_password=$$DB_PASSWORD

destroy:
	terraform -chdir=$(TF_DIR) destroy -auto-approve -var db_password=$$DB_PASSWORD
```
