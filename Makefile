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
	@echo "🚀 Releasing Helm chart"

	# Extract version
	@version_line=$$(grep '^version:' $(CHART_FILE)); \
	current_version=$$(echo $$version_line | sed 's/version:[[:space:]]*//'); \
	release_version=$$(echo $$current_version | sed 's/-SNAPSHOT//'); \
	echo "🔖 Releasing version: $$release_version"

	# Replace version in Chart.yaml (remove -SNAPSHOT)
	@sed -i.bak "s/^version:.*/version: $$release_version/" $(CHART_FILE); \
	rm -f $(CHART_FILE).bak

	# Commit release
	@git add $(CHART_FILE); \
	git commit -m "[RELEASE] Trigger release of v$$release_version"; \
	git push

	# Bump patch version for next dev
	@IFS='.'; \
	set -- $$release_version; \
	next_patch=$$(($$3 + 1)); \
	next_version="$$1.$$2.$$next_patch-SNAPSHOT"; \
	echo "🔁 Next dev version: $$next_version"; \
	sed -i.bak "s/^version:.*/version: $$next_version/" $(CHART_FILE); \
	rm -f $(CHART_FILE).bak

	# Commit dev version bump
	@git add $(CHART_FILE); \
	git commit -m "Start next development cycle: v$$next_version"; \
	git push

	@echo "✅ Release complete: v$$release_version → v$$next_version"