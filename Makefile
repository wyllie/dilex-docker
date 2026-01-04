BIN_DIR := $(HOME)/bin
WRAPPER_DIR := wrappers

# Image tags (single source of truth)
HUGO_IMAGE := wyllie/hugo:hugo0.154.2-sass1.97.1-alpine3.23.2-1
HUGO_AWS_IMAGE := wyllie/hugo-aws:hugo0.154.2-sass1.97.1-awscli2-alpine3.23.2-1
CDK_IMAGE := wyllie/cdk:awscli2-alpine3.23.2-1

.PHONY: install uninstall check-bin

check-bin:
	@mkdir -p $(BIN_DIR)

install: check-bin
	@echo "Installing docker-backed CLI wrappers into $(BIN_DIR)"
	@sed "s|@@HUGO_IMAGE@@|$(HUGO_IMAGE)|g" $(WRAPPER_DIR)/hugo > $(BIN_DIR)/hugo
	@sed "s|@@HUGO_AWS_IMAGE@@|$(HUGO_AWS_IMAGE)|g" $(WRAPPER_DIR)/aws > $(BIN_DIR)/aws
	@sed "s|@@CDK_IMAGE@@|$(CDK_IMAGE)|g" $(WRAPPER_DIR)/cdk > $(BIN_DIR)/cdk
	@chmod +x $(BIN_DIR)/hugo $(BIN_DIR)/aws $(BIN_DIR)/cdk
	@echo "✔ Installed: hugo, aws, cdk"

uninstall:
	@echo "Removing docker-backed CLI wrappers from $(BIN_DIR)"
	@rm -f $(BIN_DIR)/hugo $(BIN_DIR)/aws $(BIN_DIR)/cdk
	@echo "✔ Removed"
