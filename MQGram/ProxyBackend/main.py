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
CONTACTS_FILE = DATA_DIR / "contacts.json"


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


class ContactCreate(BaseModel):
    name: str
    url: str
    icon: str = "link"


class ContactUpdate(BaseModel):
    name: Optional[str] = None
    url: Optional[str] = None
    icon: Optional[str] = None


class ContactResponse(BaseModel):
    id: str
    name: str
    url: str
    icon: str
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


def load_contacts() -> list[dict]:
    if CONTACTS_FILE.exists():
        with open(CONTACTS_FILE) as f:
            return json.load(f)
    return []


def save_contacts(contacts: list[dict]) -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    with open(CONTACTS_FILE, "w") as f:
        json.dump(contacts, f, indent=2, ensure_ascii=False)


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


@app.get("/api/contacts", response_model=list[ContactResponse])
def list_contacts():
    """Public endpoint: returns developer contacts for all MQGram users."""
    return load_contacts()


@app.post("/api/contacts", response_model=ContactResponse, status_code=201)
def create_contact(
    contact: ContactCreate,
    authorization: Optional[str] = Header(None),
):
    """Admin only: add a developer contact link."""
    verify_admin(authorization)
    contacts = load_contacts()
    new_contact = {
        "id": str(uuid.uuid4()),
        "name": contact.name,
        "url": contact.url,
        "icon": contact.icon,
        "created_at": datetime.utcnow().isoformat() + "Z",
    }
    contacts.append(new_contact)
    save_contacts(contacts)
    return new_contact


@app.put("/api/contacts/{contact_id}", response_model=ContactResponse)
def update_contact(
    contact_id: str,
    contact: ContactUpdate,
    authorization: Optional[str] = Header(None),
):
    """Admin only: update a developer contact (name, url, icon)."""
    verify_admin(authorization)
    contacts = load_contacts()
    for c in contacts:
        if c["id"] == contact_id:
            if contact.name is not None:
                c["name"] = contact.name
            if contact.url is not None:
                c["url"] = contact.url
            if contact.icon is not None:
                c["icon"] = contact.icon
            save_contacts(contacts)
            return c
    raise HTTPException(status_code=404, detail="Contact not found")


@app.delete("/api/contacts/{contact_id}", status_code=204)
def delete_contact(
    contact_id: str,
    authorization: Optional[str] = Header(None),
):
    """Admin only: remove a developer contact."""
    verify_admin(authorization)
    contacts = load_contacts()
    new_contacts = [c for c in contacts if c["id"] != contact_id]
    if len(new_contacts) == len(contacts):
        raise HTTPException(status_code=404, detail="Contact not found")
    save_contacts(new_contacts)


@app.get("/health")
def health():
    return {"status": "ok"}
