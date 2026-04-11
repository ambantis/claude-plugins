# Trivy Installation Guide

## Install Trivy

```bash
# macOS
brew install trivy

# Arch Linux
sudo pacman -S trivy

# Any Linux (official install script)
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
  | sudo sh -s -- -b /usr/local/bin

# Verify
trivy --version
```

## Reference

- Trivy docs: https://trivy.dev/docs/
- Supported languages: https://trivy.dev/docs/latest/coverage/language/
