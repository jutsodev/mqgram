import json
import os
import uuid
from datetime import datetime
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, HTTPException, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="MQGram Proxy API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

ADMIN_TOKEN = os.environ.get("MQGRAM_ADMIN_TOKEN", "mqgram-admin-secret-change-me")
DATA_DIR = Path(os.environ.get("PERSIST_DIR", "/data"))
PROXIES_FILE = DATA_DIR / "proxies.json"


class ProxyCreate(BaseModel):
    name: str
    server: str
    port: int
    secret: str


class ProxyResponse(BaseModel):
    id: str
    name: str
    server: str
    port: int
    secret: str
    created_at: str


def load_proxies() -> list[dict]:
    if PROXIES_FILE.exists():
        with open(PROXIES_FILE) as f:
            return json.load(f)
    return []


def save_proxies(proxies: list[dict]) -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    with open(PROXIES_FILE, "w") as f:
        json.dump(proxies, f, indent=2, ensure_ascii=False)


def verify_admin(authorization: Optional[str]) -> None:
    if not authorization:
        raise HTTPException(status_code=401, detail="Missing Authorization header")
    token = authorization.replace("Bearer ", "")
    if token != ADMIN_TOKEN:
        raise HTTPException(status_code=403, detail="Invalid admin token")


@app.get("/")
def root():
    return {"service": "MQGram Proxy API", "version": "1.0.0"}


@app.get("/api/proxies", response_model=list[ProxyResponse])
def list_proxies():
    """Public endpoint: returns all proxies for all MQGram users."""
    return load_proxies()


@app.post("/api/proxies", response_model=ProxyResponse, status_code=201)
def create_proxy(
    proxy: ProxyCreate,
    authorization: Optional[str] = Header(None),
):
    """Admin only: add a new proxy server."""
    verify_admin(authorization)
    proxies = load_proxies()
    new_proxy = {
        "id": str(uuid.uuid4()),
        "name": proxy.name,
        "server": proxy.server,
        "port": proxy.port,
        "secret": proxy.secret,
        "created_at": datetime.utcnow().isoformat() + "Z",
    }
    proxies.append(new_proxy)
    save_proxies(proxies)
    return new_proxy


@app.delete("/api/proxies/{proxy_id}", status_code=204)
def delete_proxy(
    proxy_id: str,
    authorization: Optional[str] = Header(None),
):
    """Admin only: remove a proxy server."""
    verify_admin(authorization)
    proxies = load_proxies()
    new_proxies = [p for p in proxies if p["id"] != proxy_id]
    if len(new_proxies) == len(proxies):
        raise HTTPException(status_code=404, detail="Proxy not found")
    save_proxies(new_proxies)


@app.get("/health")
def health():
    return {"status": "ok"}
