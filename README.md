# springboot-app Base Chart

This is a reusable Helm base chart for Spring Boot applications.
It supports Ingress, Service, Deployment, and optional HPA.

## 📦 Requirements
- Helm 3.x
- Optional: helm-unittest plugin for testing

## 🔧 Setup

Install Helm:
```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Install helm-unittest plugin:
```bash
helm plugin install https://github.com/helm-unittest/helm-unittest
```

## ✅ Usage

### Lint the chart
```bash
helm lint charts/springboot-app
# OR
make lint
```

### Run unit tests
```bash
helm unittest charts/springboot-app
# OR
make unittest
```

### Render templates
```bash
helm template myapp charts/springboot-app -f charts/springboot-app/values.yaml
# OR
make template
```

### Run CI locally
```bash
make validate
```