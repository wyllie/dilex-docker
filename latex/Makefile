# Variables
DOCKER := /usr/local/bin/docker
PANDOC := /opt/homebrew/bin/pandoc
IMAGE  := latex
WORKDIR := $(shell pwd)
LATEXMK := latexmk
TEX_FILE := $(NAME).tex
PDF_FILE := $(NAME).pdf
DOCX_FILE := $(NAME).docx
IMAGE := wyllie/latex
PLATFORMS := linux/amd64,linux/arm64


# Default target
all: pdf

# Run LaTeX to generate PDF
pdf: pull 
	@if [ ! -f "$(WORKDIR)/$(NAME)/$(TEX_FILE)" ]; then \
		echo "Usage: make NAME=<presentation_name>"; \
		echo "The .tex file must match the directory name."; \
		exit 1; \
	fi
	@echo "Generating PDF..."
	$(DOCKER) run --mount type=bind,source=$(WORKDIR)/$(NAME),target=/files $(IMAGE) $(TEX_FILE)

# Convert LaTex to DOCX
docx: 
	@echo "Generating DOCX file..."
	$(PANDOC) $(WORKDIR)/$(NAME)/$(TEX_FILE) -o $(WORKDIR)/$(NAME)/$(DOCX_FILE)

# Spellcheck
spell:
	@echo "Running aspell -c on $(NAME)/$(TEX_FILE)"
	aspell -c $(NAME)/$(TEX_FILE)

# Watch for changes (requires fswatch or inotify-tools)
watch:
	@echo "Watching for changes to $(TEX_FILE)..."
	fswatch -o $(WORKDIR)/$(NAME)/$(TEX_FILE) | xargs -n1 -I{} make NAME=$(NAME) pdf

# Build the Docker image
build:
	@echo "Building Docker image..."
	$(DOCKER) build -t $(IMAGE) .

# Build and push multi-arch image to Docker Hub
build-push:
	@echo "Building and pushing multi-arch image for $(PLATFORMS)..."
	$(DOCKER) buildx create --use --name multiarch-builder --driver docker-container --bootstrap || true
	$(DOCKER) buildx build \
		--platform $(PLATFORMS) \
		--push \
		-t $(IMAGE):latest \
		.

# Pull the Docker image from Docker Hub
pull:
	@echo "Pulling Docker image from Docker Hub..."
	$(DOCKER) pull $(IMAGE):latest

# Clean up auxiliary files only
clean:
	@if [ -z "$(NAME)" ]; then \
		echo "Usage: make clean NAME=<presentation_name>"; \
		exit 1; \
	fi
	@echo "Cleaning auxiliary files for $(NAME)..."
	rm -f $(WORKDIR)/$(NAME)/*.aux \
	      $(WORKDIR)/$(NAME)/*.log \
	      $(WORKDIR)/$(NAME)/*.out \
	      $(WORKDIR)/$(NAME)/*.toc \
	      $(WORKDIR)/$(NAME)/*.bbl \
	      $(WORKDIR)/$(NAME)/*.fls \
	      $(WORKDIR)/$(NAME)/*.fdb_latexmk \
	      $(WORKDIR)/$(NAME)/*.blg

# Clean up everything, including PDF and DOCX
really-clean: clean
	@echo "Removing PDF and DOCX files for $(NAME)..."
	rm -f $(WORKDIR)/$(NAME)/$(PDF_FILE) \
	      $(WORKDIR)/$(NAME)/$(DOCX_FILE)

.PHONY: build build-push pdf docx watch clean really-clean all
