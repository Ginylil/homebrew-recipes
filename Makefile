PYTHON ?= python3
VERSION ?=
SHA256 ?=
META_DIR ?= .tmp
META_FILE ?= $(META_DIR)/release-meta.json

.PHONY: help verify-release update-formula test

help:
	@echo "Targets:"
	@echo "  make verify-release VERSION=x.y.z [SHA256=<64-hex>]"
	@echo "  make update-formula VERSION=x.y.z [SHA256=<64-hex>]"
	@echo "  make test"

verify-release:
	@test -n "$(VERSION)" || (echo "VERSION is required, for example: make verify-release VERSION=0.0.26" && exit 1)
	@mkdir -p "$(META_DIR)"
	@$(PYTHON) scripts/verify_release.py --version "$(VERSION)" $(if $(SHA256),--sha256 "$(SHA256)",) --output-json "$(META_FILE)"

update-formula:
	@test -n "$(VERSION)" || (echo "VERSION is required, for example: make update-formula VERSION=0.0.26" && exit 1)
	@mkdir -p "$(META_DIR)"
	@$(PYTHON) scripts/verify_release.py --version "$(VERSION)" $(if $(SHA256),--sha256 "$(SHA256)",) --output-json "$(META_FILE)"
	@$(PYTHON) scripts/update_formula.py --version "$(VERSION)" --metadata-json "$(META_FILE)"

test:
	@$(PYTHON) -m unittest discover -s tests -p 'test_*.py' -v
