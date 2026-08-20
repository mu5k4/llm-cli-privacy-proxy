FROM ghcr.io/praetorian-inc/noseyparker:v0.22.0 AS noseyparker

FROM python:3.12.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends libstdc++6 && rm -rf /var/lib/apt/lists/*

COPY --from=noseyparker /usr/local/bin/noseyparker /usr/local/bin/noseyparker

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY proxy.py .

CMD ["uvicorn", "proxy:app", "--host", "0.0.0.0", "--port", "8000"]



