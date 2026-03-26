# Using slim variant to keep the image lightweight
FROM python:3.11-slim

# Prevents Python from writing .pyc files and enables stdout/stderr logging
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Copy requirements first — this layer is cached unless requirements change
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Now copy the rest of the application code
COPY . .

# Non-root user for security — never run containers as root in prod
RUN adduser --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

EXPOSE 5000

# Gunicorn for production, 2 workers is enough for a demo
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]
