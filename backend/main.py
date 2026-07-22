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
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from .routers.ai import router as ai_router
from .services.limiter import limiter

# ─── Config ───────────────────────────────────────────────────────

load_dotenv()

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(name)s | %(levelname)s | %(message)s",
)
logger = logging.getLogger("flowos")

# ─── App ──────────────────────────────────────────────────────────

app = FastAPI(
    title="FlowOS AI Backend",
    version="0.1.0",
    description="AI proxy for FlowOS productivity app. All LLM calls are server-side.",
)

import time

@app.middleware("http")
async def log_requests(request: Request, call_next):
    start = time.time()
    response = await call_next(request)
    duration = time.time() - start
    logger.info(f"{request.method} {request.url.path} {response.status_code} {duration:.3f}s")
    return response

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# ─── CORS ─────────────────────────────────────────────────────────

is_dev = os.getenv("ENVIRONMENT", "development").lower() == "development"

if is_dev:
    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
else:
    allowed_origins_str = os.getenv("CORS_ALLOWED_ORIGINS")
    if not allowed_origins_str:
        raise ValueError("CORS_ALLOWED_ORIGINS environment variable is required in production")
    allowed_origins = [o.strip() for o in allowed_origins_str.split(",") if o.strip()]
    app.add_middleware(
        CORSMiddleware,
        allow_origins=allowed_origins,
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
