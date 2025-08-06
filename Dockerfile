FROM n8nio/n8n:1.105.3

ENV N8N_PORT=8080 \
   N8N_HOST=0.0.0.0 \
   NODE_OPTIONS="--enable-source-maps"

HEALTHCHECK --start-period=2m --interval=30s --timeout=10s --retries=3 \
 CMD curl -fSs http://localhost:8080/health || exit 1

EXPOSE 8080
