CHART_DIR := charts/springboot-app
VALUES_FILE := $(CHART_DIR)/values.yaml

.PHONY: lint test template validate install package bump-patch

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

bump-patch:
	@echo "📦 Bumping chart patch version..."
	@old_version=$$(grep '^version:' $(CHART_DIR)/Chart.yaml | awk '{print $$2}'); \
	IFS='.' read -r major minor patch <<< "$$old_version"; \
	new_version="$$major.$$minor.$$((patch + 1))"; \
	echo "🔢 New version: $$new_version"; \
	sed -i.bak "s/^version:.*/version: $$new_version/" $(CHART_FILE); \
	rm -f $(CHART_FILE).bak; \
	git add $(CHART_FILE); \
	git commit -m "Bump chart version to $$new_version"; \
	git push; \
	git tag "v$$new_version"; \
	git push origin "v$$new_version"