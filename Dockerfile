FROM n8nio/n8n:1.105.3

# Configuração explícita de porta
ENV N8N_PORT=8080 \
    N8N_HOST=0.0.0.0 \
    N8N_PROTOCOL=http \
    NODE_ENV=production

# Validação de porta durante o build
RUN if [ "$N8N_PORT" -lt 1024 ]; then \
    apk add libcap && \
    setcap 'cap_net_bind_service=+ep' $(which node); \
  fi

# Configuração de usuário não-root
RUN addgroup -g 2000 apprunner && \
    adduser -u 2000 -G apprunner -S apprunner && \
    chown -R apprunner:apprunner /home/node

# Healthcheck aprimorado
HEALTHCHECK --interval=15s --timeout=5s --retries=3 \
  CMD curl -fSs http://localhost:8080/health | grep -q '"status":"ok"' || exit 1

USER apprunner
EXPOSE 8080
CMD ["n8n", "start"]
