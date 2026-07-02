.PHONY: all build clean build-x86_64 build-aarch64 shell rebuild

DOCKER_IMAGE = koreos-builder
DOCKER_TAG = latest
OUTPUT_DIR = $(CURDIR)/output
ASSETS_DIR = $(CURDIR)/assets

all: build

build: build-x86_64 build-aarch64

build-x86_64:
	@echo "Building Kore OS x86_64 ISO..."
	@mkdir -p $(OUTPUT_DIR)
	@docker compose -f docker-compose.yml run --rm koreos-builder

build-aarch64:
	@echo "Building Kore OS aarch64 image..."
	@mkdir -p $(OUTPUT_DIR)
	@docker compose -f docker-compose.yml run --rm -e BUILD_MODE=aarch64 -e ARCH=aarch64 koreos-builder

shell:
	@echo "Opening shell in build environment..."
	@mkdir -p $(OUTPUT_DIR)
	@docker compose -f docker-compose.yml run --rm -e BUILD_MODE=shell koreos-builder

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(OUTPUT_DIR)/*
	@docker compose -f docker-compose.yml down -v 2>/dev/null || true
	@echo "Done."

rebuild: clean build

status:
	@echo "Kore OS Build System"
	@echo "==================="
	@echo "Output directory: $(OUTPUT_DIR)"
	@echo "Assets directory: $(ASSETS_DIR)"
	@ls -la $(OUTPUT_DIR) 2>/dev/null || echo "No builds yet."
