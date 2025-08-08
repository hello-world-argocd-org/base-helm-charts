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
	@echo "🚀 Starting Helm chart release..."

	# Get current version, strip carriage returns
	@current_version=$$(grep '^version:' $(CHART_FILE) | cut -d' ' -f2 | tr -d '\r'); \
	release_version=$$(echo $$current_version | sed 's/-SNAPSHOT//'); \
	echo "🔖 Releasing version: $$release_version"

	# Update Chart.yaml: remove -SNAPSHOT
	@awk -v new_ver="version: $$release_version" \
		'{ if ($$1 == "version:") print new_ver; else print $$0 }' \
		$(CHART_FILE) > $(CHART_FILE).tmp && mv $(CHART_FILE).tmp $(CHART_FILE)

	# Commit and push release version
	@git add $(CHART_FILE) && \
	git commit -m "[RELEASE] Trigger release of v$$release_version" && \
	git push

	# Calculate next patch version
	@MAJOR=$$(echo $$release_version | cut -d. -f1); \
	MINOR=$$(echo $$release_version | cut -d. -f2); \
	PATCH=$$(echo $$release_version | cut -d. -f3); \
	NEXT_PATCH=$$(expr $$PATCH + 1); \
	next_version="$$MAJOR.$$MINOR.$$NEXT_PATCH-SNAPSHOT"; \
	echo "🔁 Bumping to next dev version: $$next_version"

	# Update Chart.yaml again
	@awk -v new_ver="version: $$next_version" \
		'{ if ($$1 == "version:") print new_ver; else print $$0 }' \
		$(CHART_FILE) > $(CHART_FILE).tmp && mv $(CHART_FILE).tmp $(CHART_FILE)

	# Commit and push dev bump
	@git add $(CHART_FILE) && \
	git commit -m "Start next development cycle: v$$next_version" && \
	git push

	@echo "✅ Done: Released v$$release_version → Bumped to $$next_version"