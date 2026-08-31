FROM ghcr.io/praetorian-inc/noseyparker@sha256:047ab4f31db62b1531140e2b4229b78f7a6ead275fb7ef97b9b957b37c7e0017 AS noseyparker

FROM python:3.12.13-slim@sha256:229a2c5bfa27522db7815ea81f9bed70af17ccb9de9fc7ad142b1877b5830d36

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update && apt-get install -y --no-install-recommends libstdc++6 && rm -rf /var/lib/apt/lists/*

COPY --from=noseyparker /usr/local/bin/noseyparker /usr/local/bin/noseyparker

WORKDIR /app

COPY pyproject.toml privacy-service.lock ./
RUN pip install --no-cache-dir --require-hashes -r privacy-service.lock

COPY privacy-service/app.py ./
COPY privacy-service/proxy.py ./

CMD ["uvicorn", "proxy:app", "--host", "0.0.0.0", "--port", "8000"]

