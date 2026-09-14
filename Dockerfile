FROM python:3.9-slim

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml ./
COPY speaker_recognition ./speaker_recognition

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

RUN uv pip install --system --no-cache -e ".[server]"

RUN mkdir -p /data/embeddings

# Bake the ECAPA-TDNN speaker embedding model into the image so containers
# don't need Hugging Face Hub access to start (and start in the same time
# on every run instead of downloading ~80MB on first boot).
RUN python3 -c "from speaker_recognition.recognizer import recognizer"

EXPOSE 8099

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8099/health').read()"

ENV HOST=0.0.0.0 \
    PORT=8099 \
    LOG_LEVEL=INFO \
    ACCESS_LOG=true \
    EMBEDDINGS_DIR=/data/embeddings

CMD ["python", "-m", "speaker_recognition"]
