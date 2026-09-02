FROM mcr.microsoft.com/powershell:7.5-ubuntu-24.04

ARG DEBIAN_FRONTEND=noninteractive

ENV PATH="/opt/catalog-tools/bin:${PATH}"

RUN apt-get update \
    && apt-get install --yes --no-install-recommends bash git python3 python3-venv shellcheck \
    && python3 -m venv /opt/catalog-tools \
    && /opt/catalog-tools/bin/pip install --no-cache-dir "ruff==0.16.5" "yamllint==1.37.1" \
    && pwsh -NoProfile -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; Install-Module PSScriptAnalyzer -RequiredVersion 1.25.0 -Scope AllUsers -Force" \
    && rm -rf /var/lib/apt/lists/*
