# Makefile

# Collect app name from Cargo.toml
APP_NAME = $(shell grep '^name' Cargo.toml | head -n 1 | sed 's/name = "\(.*\)"/\1/')

IMAGE_NAME = $(APP_NAME):latest
PROJECT_DIR = $(shell pwd)

# File names
TMPL_FILE = $(PROJECT_DIR)/deploy/rust-app.container.tmpl
LOCAL_QUADLET_FILE = $(PROJECT_DIR)/deploy/rust-app.container
LOCAL_TIMER_FILE = $(PROJECT_DIR)/deploy/rust-app.timer

# Systemd Paths
TIMER_NAME = $(APP_NAME).timer
QUADLET_FOLDER = $(HOME)/.config/containers/systemd
SYSTEMD_FOLDER = $(HOME)/.config/systemd/user
QUADLET_PATH = $(QUADLET_FOLDER)/$(APP_NAME).container
SYSTEMD_PATH = $(SYSTEMD_FOLDER)/$(TIMER_NAME)

CTL = systemctl --user

.PHONY: build install uninstall generate

# 1. Generate the absolute paths into the container file
generate:
	@echo "Generating absolute paths for Quadlet..."
	cat $(TMPL_FILE) > $(LOCAL_QUADLET_FILE)
	sed -i 's|{{PROJECT_DIR}}|$(PROJECT_DIR)|g' $(LOCAL_QUADLET_FILE)
	sed -i 's|{{IMAGE_NAME}}|$(IMAGE_NAME)|g' $(LOCAL_QUADLET_FILE)

build:
	podman build --build-arg APP_NAME=$(APP_NAME) -t $(IMAGE_NAME) .

install: build generate
	@echo "Setting up directories..."
	mkdir -p $(PROJECT_DIR)/data $(PROJECT_DIR)/secrets
	chmod 700 $(PROJECT_DIR)/secrets

	@if [ ! -f $(PROJECT_DIR)/secrets/.env.prod ]; then \
		touch $(PROJECT_DIR)/secrets/.env.prod; \
		chmod 600 $(PROJECT_DIR)/secrets/.env.prod; \
	fi

	@echo "Linking to Systemd..."
	mkdir -p $(QUADLET_FOLDER) $(SYSTEMD_FOLDER)
	ln -sf $(LOCAL_QUADLET_FILE) $(QUADLET_PATH)
	ln -sf $(LOCAL_TIMER_FILE) $(SYSTEMD_PATH)

	$(CTL) daemon-reload
	$(CTL) enable --now $(TIMER_NAME)
	@echo "Installed successfully at $(PROJECT_DIR)"

uninstall:
	-$(CTL) disable --now $(TIMER_NAME)
	rm -f $(QUADLET_PATH)
	rm -f $(SYSTEMD_PATH)
	rm -f $(LOCAL_QUADLET_FILE)
	$(CTL) daemon-reload
	$(CTL) reset-failed
	@echo "Cleaned up systemd links and generated files."

reload:
	$(CTL) daemon-reload
	$(CTL) restart $(TIMER_NAME)

status:
	$(CTL) list-timers --all | grep $(TIMER_NAME)
	$(CTL) status $(TIMER_NAME)

logs:
	journalctl --user -u my-task.service -f
