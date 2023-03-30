This repo serves these purposes:
- Sharing an instruction for the development environment setup.
- Enabling reproducible and easy deployments to staging and production environments.
    - We leave the version unspecified for some dependencies (namely system dependencies, installed via `apt`). This is ok, but we should be explicit about doing this.
    - Git history records the past working versions on production. It helps us revert to old deployments in case of problems.

## Development environment

1. If your host OS is Windows, [install WSL 2 and Linux](https://learn.microsoft.com/en-us/windows/wsl/install).
    All below instructions are run in a Linux or Mac.
1. [Set up your GitHub account with an SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh).
1. Install a node version manager, e.g. [nvm](https://github.com/nvm-sh/nvm).
1. Below, if you're developing the vis only, skip database and api.
1. First-time setup
    1. Database
        - Option 1: docker
            1. [Install docker](https://docs.docker.com/get-docker/).
            1. Dump the test data into MongoDB.
                ```sh
                cd ccn-coverage-deploy/
                docker compose run --rm \
                    -v "${PWD}/assets/dev/mongo-data-mock:/mongo-data-mock" \
                    mongo \
                    /mongo-data-mock/initialize.sh
                ```
        - Option 2: mongo version manager
            - There are several tools for this. Search online for the most up-to-date recommendations.
    1. Api
        ```sh
        cd your-development-dir/
        git clone git@github.com:Local-Connectivity-Lab/ccn-coverage-api.git
        ```
    1. Vis
        ```sh
        cd your-development-dir/
        git clone git@github.com:Local-Connectivity-Lab/ccn-coverage-vis.git
        ```
1. Bringup & Teardown
    1. Database
        - Option 1: docker
            1. Bringup:
                ```sh
                cd ccn-coverage-deploy/
                docker compose up -d
                ```
            1. Teardown:
                ```sh
                cd ccn-coverage-deploy/
                docker compose down
                ```
    1. Api
        1. Bringup:
            ```sh
            cd ccn-coverage-api/
            nvm use
            npm start
            ```
        1. Teardown: Ctrl + c
    1. Vis
        1. Bringup:
            ```sh
            cd ccn-coverage-vis/
            nvm use
            npm start
            # If you want vis to talk to your local api, specify the below environment variable.
            # REACT_APP__API_URL='http://localhost:3000' npm start
            ```
        1. Teardown: Ctrl + c

## Staging and Production environments

Fist-time setup:
1. Provision a compute instance on cloud.
    - CPUs = 1
    - Memory = 2GB
1. Ansible depends on python. Install a python version manager, e.g. [pyenv](https://github.com/pyenv/pyenv#installation). Then, install a python runtime: e.g. `pyenv install 3.11`.
1. [Install ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) (`pip install ansible`).
1. Copy Api's keys to [here](./assets/prod/api-keys/).
1. Configure hosts to be targetted by Ansible. In your `~/.ssh/config`:
    ```
    Host ccn_coverage_staging
        HostName foo.bar.com
        ForwardAgent yes
        ...
    ```

Do deploy:
1. Back up data.
    1. `ssh ccn_coverage_prod`
    1. Inside ccn_coverage_prod :
        ```sh
        cd /tmp/
        rm -r ./dump.tgz ./dump/
        mongodump
        tgz -zxf ./dump.tgz ./dump/
        ```
    1. Upload the dump.tgz to our Google Drive.
    1. Inside ccn_coverage_prod :
        ```sh
        rm -r /tmp/.dump.tgz /tmp/dump/
        ```
1. Configure a target environment via Ansible.
    ```sh
    cd ccn-coverage-deploy/
    ansible-playbook -i ./environments/staging ./playbook.yaml
    ```
1. Commit whatever changes you made to this `ccn-coverage-deploy` repo, and push it.
