PROVIDERS = rancher/rancher-common rancher/aws rancher/hcloud
CLOUD_PROVIDERS = rancher/aws rancher/hcloud

upgrade-targets = $(addprefix upgrade-, $(PROVIDERS))
fmt-targets = $(addprefix fmt-, $(PROVIDERS))
validate-targets = $(addprefix validate-, $(PROVIDERS))
plan-targets = $(addprefix plan-, $(CLOUD_PROVIDERS))

upgrade: $(upgrade-targets)
$(upgrade-targets): upgrade-%: %
	cd $< && terraform init -upgrade

fmt: $(fmt-targets)
$(fmt-targets): fmt-%: %
	cd $< && terraform fmt

validate: $(validate-targets)
$(validate-targets): validate-%: %
	cd $< && terraform validate

plan: $(plan-targets)
$(plan-targets): plan-%: %
	cd $< && terraform plan

.PHONY: clean
clean:
	rm */*/terraform.tfstate.backup
