This repo serves these purposes:
- Sharing an instruction for the development environment setup.
- Enabling reproducible and easy deployments to staging and production environments.
    - We leave the version unspecified for some dependencies (namely system dependencies, installed via `apt`). This is ok, but we should be explicit about doing this.
    - Git history records the past working versions on production. It helps us revert to old deployments in case of problems.

## Development environment

1. If your host OS is Windows, [install WSL 2 and Linux](https://learn.microsoft.com/en-us/windows/wsl/install).
    All below instructions are run in a Linux or Mac.
1. Prepare your ssh key.
    To generate a new key, see [here](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent?platform=linux).
    If your host OS is Windows, [copy your key(s)](https://devblogs.microsoft.com/commandline/sharing-ssh-keys-between-windows-and-wsl-2/) between the host Windows and the guest Linux.
1. [Set up your GitHub account with your SSH key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account).
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
1. Your local environment should be configured with an ssh key that authorizes you on GitHub _and_ on the remote environment. In addition, every time you ssh into a remote environment (staging or production), you want to "forward" your local ssh key there. To do so:
    1. Edit your `~/.ssh/config`. Add these lines:
        ```
        Host *.seattlecommunitynetwork.org
            ForwardAgent yes
        ```
    1. Edit your shell configuration file: `~/.bashrc` on Linux or `~/.zshrc` on Mac. Add these lines. (This may be optional, but is likely needed on a WSL Linux.)
        ```sh
        if [ -z "$SSH_AUTH_SOCK" ] ; then
            eval `ssh-agent -s`
            ssh-add
        fi
        ```
1. Ansible depends on python. Install a python version manager, e.g. [pyenv](https://github.com/pyenv/pyenv#installation). Then, install a python runtime: e.g. `pyenv install 3.11`.
1. [Install ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) (`pip install ansible`).
1. Copy Api's keys to [here](./assets/prod/api-keys/).

Do deploy:
1. Back up data.
    1. `ssh <environment>.seattlecommunitynetwork.org`
    1. At the remote environment:
        ```sh
        cd /tmp/
        rm -r ./dump.tgz ./dump/
        mongodump
        tgz -zxf ./dump.tgz ./dump/
        ```
    1. Upload the dump.tgz to our Google Drive.
    1. At the remote environment:
        ```sh
        rm -r /tmp/.dump.tgz /tmp/dump/
        ```
1. Configure a target environment via Ansible.
    ```sh
    cd ccn-coverage-deploy/
    ansible-playbook -i ./environments/staging ./playbook.yaml
    ```
1. Commit whatever changes you made to this `ccn-coverage-deploy` repo, and push it.
