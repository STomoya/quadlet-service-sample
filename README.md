# quadlet-service-sample

Sample project of a Quadlet systemd service.

## What

- Scheduled execution of a Rust application using Quadlet.

## Requirements

- systemd
- podman

## Usage

- Install service

```sh
make install
```

- Uninstall service

```sh
make uninstall
```

- Reload

```sh
make reload
```

- logs

```sh
make logs
```
