FROM python:3.11-slim

# Paquetes del sistema (si necesitas gcc/krb para drivers, ajusta)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git && \
    rm -rf /var/lib/apt/lists/*

# Instalar dbt-trino
RUN pip install --no-cache-dir dbt-trino==1.8.2

# Crear usuario no root
RUN useradd -ms /bin/bash dbtuser
USER dbtuser
WORKDIR /home/dbtuser/app

# Copiamos solo el proyecto dbt
COPY --chown=dbtuser:dbtuser . /home/dbtuser/app

# Por defecto, usaremos el profiles en ./profiles
ENV DBT_PROFILES_DIR=/home/dbtuser/app/profiles

CMD ["bash"]
