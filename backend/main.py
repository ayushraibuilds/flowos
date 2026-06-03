"""FlowOS AI Backend — FastAPI application.

Serves AI-powered endpoints for:
- Daily reports with personalized insights
- Break content suggestions (riddles, facts, breathing, quotes)
- Brain dump text → sorted actionable tasks
- Weekly review with reflection questions

All LLM calls go through this proxy — the Flutter app never calls AI directly.
"""

import logging
import os

from dotenv import load_dotenv
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address

from .routers.ai import router as ai_router

# ─── Config ───────────────────────────────────────────────────────

load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(name)s | %(levelname)s | %(message)s",
)
logger = logging.getLogger("flowos")

# ─── Rate Limiting ────────────────────────────────────────────────

limiter = Limiter(key_func=get_remote_address)

# ─── App ──────────────────────────────────────────────────────────

app = FastAPI(
    title="FlowOS AI Backend",
    version="0.1.0",
    description="AI proxy for FlowOS productivity app. All LLM calls are server-side.",
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# ─── CORS ─────────────────────────────────────────────────────────

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:*",
        "http://127.0.0.1:*",
        # Add your production domain when deploying
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Routes ───────────────────────────────────────────────────────

app.include_router(ai_router)


@app.get("/")
async def root():
    return {"service": "FlowOS AI Backend", "version": "0.1.0", "status": "ok"}


@app.get("/health")
async def health():
    has_key = bool(os.getenv("GEMINI_API_KEY"))
    return {
        "status": "healthy",
        "ai_configured": has_key,
    }
