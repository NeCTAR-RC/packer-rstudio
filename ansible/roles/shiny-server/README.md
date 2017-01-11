## shiny-server

Set up (the latest version of) [Shiny Server](https://www.rstudio.com/products/shiny/shiny-server/) in Debian-like systems.

#### Requirements

* `r-base` (will not be installed)

#### Variables

shiny_server_version: 1.5.1.834
shiny_server_install: []

shiny_server_www_port: 3838
shiny_server_www_address: 0.0.0.0
shiny_server_site_dir: /srv/shiny-server
andy@russell ~/tmp/r-studio/heat/rstudio-cluster prod-andy-nectardevs $ cat roles/shiny-server/vars/main.yml 
# vars file for shiny-server
---
shiny_server_dependencies: []
shiny_server_downloads_path: /var/lib/ansible/rstudio-server/downloads


* `shiny_server_version` [default: `1.5.1.834`]: Version to install
* `shiny_server_install` [default: `[]`]: Additional packages to install (e.g. `r-base`)

* `shiny_server_www_port` [default: `3838`]: The port you want RStudio to listen on
* `shiny_server_www_address` [default: `0.0.0.0`]: The address you want Shiny server to listen on
* `shiny_server_site_dir` [default: `/srv/shiny-server`]: Where to install Shiny server

## Dependencies

None


#### Example

```yaml
---
- hosts: all
  roles:
    - shiny-server
```

#### License

MIT

#### Author Information

Mischa ter Smitten
Andy Botting
