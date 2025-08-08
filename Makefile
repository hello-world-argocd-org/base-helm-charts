CHART_DIR := charts/springboot-app
VALUES_FILE := $(CHART_DIR)/values.yaml
CHART_FILE := $(CHART_DIR)/Chart.yaml

.PHONY: lint test template validate install package release

## Lint the Helm chart
lint:
	helm lint $(CHART_DIR)

## Run Helm unit tests
test:
	helm unittest $(CHART_DIR)

## Render templates (for debugging)
template:
	helm template myapp $(CHART_DIR) -f $(VALUES_FILE)

## Validate everything (lint + test)
validate: lint test template

## Install Helm and plugins (one-time setup)
install:
	curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
	helm plugin install https://github.com/helm-unittest/helm-unittest || true

## Package the chart as a .tgz file
package:
	helm package $(CHART_DIR)

release:
	@echo "Preparing Helm chart release..."
	@version=$$(grep '^version:' $(CHART_FILE) | awk '{print $$2}'); \
	echo "Releasing version $$version..."; \
	git add $(CHART_FILE); \
	git commit -m "Release Helm chart v$$version" || echo "Already committed"; \
	git push; \
	git tag "v$$version"; \
	git push origin "v$$version"; \
	echo "Preparing next patch version..."; \
	IFS='.' read -r major minor patch <<< "$$version"; \
	next_version="$$major.$$minor.$$((patch + 1))"; \
	sed -i.bak "s/^version:.*/version: $$next_version/" $(CHART_FILE); \
	rm -f $(CHART_FILE).bak; \
	git add $(CHART_FILE); \
	git commit -m "Bump chart version to $$next_version"; \
	git push; \
	echo "Released v$$version, bumped to $$next_version"