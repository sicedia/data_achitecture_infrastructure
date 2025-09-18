FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git && \
    rm -rf /var/lib/apt/lists/*

# Copiar requirements y instalar dependencias
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

RUN useradd -ms /bin/bash dbtuser
USER dbtuser
WORKDIR /home/dbtuser/app

COPY --chown=dbtuser:dbtuser . /home/dbtuser/app

# Instalar paquetes de dbt
RUN dbt deps

ENV DBT_PROFILES_DIR=/home/dbtuser/app/profiles

CMD ["dbt", "--help"]
