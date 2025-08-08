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

	@current=$$(grep '^version:' $(CHART_FILE) | cut -d' ' -f2); \
	release_version=$$(echo $$current | sed 's/-SNAPSHOT//'); \
	echo "🔖 Releasing version: $$release_version"; \
	sed -i.bak "s/^version:.*/version: $$release_version/" $(CHART_FILE); \
	rm -f $(CHART_FILE).bak; \
	git add $(CHART_FILE); \
	git commit -m "[RELEASE] Trigger release of v$$release_version"; \
	git push;

	@next_version=$$( \
		IFS='.' read -r MAJOR MINOR PATCH <<< "$$(echo $$release_version | cut -d'-' -f1)"; \
		echo "$$MAJOR.$$MINOR.$$((PATCH + 1))-SNAPSHOT" \
	); \
	echo "🔁 Bumping to next dev version: $$next_version"; \
	sed -i.bak "s/^version:.*/version: $$next_version/" $(CHART_FILE); \
	rm -f $(CHART_FILE).bak; \
	git add $(CHART_FILE); \
	git commit -m "Start next development cycle: v$$next_version"; \
	git push;

	@echo "✅ Done. Released v$$release_version → next: v$$next_version"