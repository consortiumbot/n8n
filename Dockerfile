# Estágio de construção
FROM node:22.17-alpine3.22 AS builder

ARG N8N_VERSION=1.105.3
ENV NODE_ENV=production \
    NODE_ICU_DATA=/usr/local/lib/node_modules/full-icu \
    TINI_VERSION=v0.19.0

# Instalação segura de dependências
RUN apk add --no-cache --virtual .build-deps \
    python3 \
    make \
    g++ \
    git \
    curl \
&& curl -fsSL https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static -o /sbin/tini \
&& chmod +x /sbin/tini \
&& apk del .build-deps

# Configuração de usuário não privilegiado
RUN addgroup -g 2000 -S apprunner \
&& adduser -u 2000 -S apprunner -G apprunner

WORKDIR /app

# Gerenciamento inteligente de dependências
COPY --chown=apprunner:apprunner package*.json ./
RUN npm ci --omit=dev --prefer-offline

# Estágio de produção
FROM node:22.17-alpine3.22

# Configurações de segurança
COPY --from=builder /sbin/tini /sbin/tini
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group

USER apprunner
WORKDIR /app

# Cópia otimizada de artefatos
COPY --chown=apprunner:apprunner --from=builder /app/node_modules ./node_modules
COPY --chown=apprunner:apprunner . .

# Variáveis de ambiente
ENV N8N_PORT=8080 \
    N8N_HOST=0.0.0.0 \
    N8N_ENCRYPTION_KEY_FILE=/run/secrets/n8n_encryption_key

# Healthcheck avançado
HEALTHCHECK --interval=30s --timeout=10s --start-period=2m \
  CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080/tcp
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "bin/n8n"]

# Metadados
LABEL maintainer="Equipe DevOps <devops@empresa.com>" \
      org.opencontainers.image.version="1.105.3" \
      br.com.empresa.security.level="high"
