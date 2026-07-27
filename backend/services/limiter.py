"""Rate Limiter Service — slowapi configuration to prevent circular imports."""

import os
import logging
import jwt
from fastapi import Request
from slowapi import Limiter
from slowapi.util import get_remote_address

logger = logging.getLogger("flowos.limiter")

def get_user_or_ip_key(request: Request) -> str:
    """Determine rate limiting key: verified user ID if valid JWT provided, fallback to client IP.
    
    CRITICAL: Never mutates request.state to prevent unverified identity bypasses.
    """
    auth_header = request.headers.get("Authorization")
    if auth_header and auth_header.startswith("Bearer "):
        try:
            token = auth_header.split(" ")[1]
            jwt_secret = os.getenv("SUPABASE_JWT_SECRET") or os.getenv("JWT_SECRET")
            if jwt_secret:
                # Verify token signature before trusting the sub claim for rate limiting
                payload = jwt.decode(
                    token,
                    jwt_secret,
                    algorithms=["HS256"],
                    options={"verify_aud": False}
                )
                user_id = payload.get("sub")
                if user_id and isinstance(user_id, str):
                    return f"user:{user_id}"
        except Exception:
            # Token signature failed, expired, or malformed -> fallback to IP key
            pass

    client_ip = get_remote_address(request) or "127.0.0.1"
    return f"ip:{client_ip}"

env = os.getenv("ENVIRONMENT", "development").lower()
redis_url = os.getenv("REDIS_URL")

if redis_url:
    logger.info("Initializing Rate Limiter with Redis storage.")
    limiter = Limiter(key_func=get_user_or_ip_key, storage_uri=redis_url)
elif env == "production":
    raise ValueError("REDIS_URL environment variable is required in production for multi-worker rate limiting.")
else:
    logger.warning("REDIS_URL not configured. Rate limiting falls back to process-local memory.")
    limiter = Limiter(key_func=get_user_or_ip_key)
