# MQGram Proxy Backend

FastAPI backend for managing MQGram proxy servers. Admin can add/delete proxies, all MQGram users see the current list.

## API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/proxies` | Public | List all proxy servers |
| POST | `/api/proxies` | Admin | Add a new proxy server |
| DELETE | `/api/proxies/{id}` | Admin | Delete a proxy server |
| GET | `/health` | Public | Health check |

## Deploy

### Docker

```bash
docker build -t mqgram-proxy .
docker run -d -p 8080:8080 \
  -e MQGRAM_ADMIN_TOKEN=your-secret-token \
  -v mqgram-data:/data \
  mqgram-proxy
```

### Fly.io

```bash
fly launch --name mqgram-proxy
fly secrets set MQGRAM_ADMIN_TOKEN=your-secret-token
fly volumes create mqgram_data --size 1
fly deploy
```

### Environment Variables

- `MQGRAM_ADMIN_TOKEN` — Admin auth token (required for POST/DELETE)
- `PERSIST_DIR` — Directory for storing proxy data (default: `/data`)

## Usage

Add a proxy:
```bash
curl -X POST https://your-server/api/proxies \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-secret-token" \
  -d '{"name": "🇷🇺 Russia", "server": "proxy.example.com", "port": 443, "secret": "abcdef123456"}'
```

List proxies:
```bash
curl https://your-server/api/proxies
```

Delete a proxy:
```bash
curl -X DELETE https://your-server/api/proxies/{proxy-id} \
  -H "Authorization: Bearer your-secret-token"
```
