---
name: python-error-tracking
description: Add Sentry error tracking and performance monitoring to Python projects (Django/FastAPI). Use when adding error handling, creating views/endpoints, background tasks, or tracking performance. ALL ERRORS MUST BE CAPTURED TO SENTRY.
---

# Python Sentry Integration Skill

## Purpose

Enforce comprehensive Sentry error tracking and performance monitoring across Python backend services (Django/FastAPI).

## When to Use This Skill

- Adding error handling to any code
- Creating new views, endpoints, or routes
- Instrumenting background tasks (Celery/asyncio)
- Tracking database performance
- Adding custom performance spans
- Handling exceptions

## 🚨 CRITICAL RULE

**ALL ERRORS MUST BE CAPTURED TO SENTRY** - No exceptions. Never use print() or logging alone for errors.

---

## Installation

### FastAPI

```bash
pip install sentry-sdk[fastapi]
```

```python
# main.py (FIRST import)
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration
from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration

sentry_sdk.init(
    dsn="your-sentry-dsn",
    integrations=[
        FastApiIntegration(),
        SqlalchemyIntegration(),
    ],
    traces_sample_rate=1.0,  # Adjust for production
    profiles_sample_rate=1.0,
    environment="production",  # or "development"
)

from fastapi import FastAPI
app = FastAPI()
```

### Django

```bash
pip install sentry-sdk[django]
```

```python
# settings.py (at the top)
import sentry_sdk
from sentry_sdk.integrations.django import DjangoIntegration

sentry_sdk.init(
    dsn="your-sentry-dsn",
    integrations=[DjangoIntegration()],
    traces_sample_rate=1.0,
    send_default_pii=True,  # Send user data (be careful with GDPR)
    environment="production",
)
```

---

## Error Handling Patterns

### 1. FastAPI Endpoint Error Handling

```python
from fastapi import APIRouter, HTTPException
import sentry_sdk

router = APIRouter()

@router.post("/users")
async def create_user(user_data: UserCreate):
    try:
        user = await user_service.create_user(user_data)
        return user
    except ValueError as e:
        # Business logic errors - don't capture to Sentry
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        # Unexpected errors - MUST capture to Sentry
        sentry_sdk.capture_exception(e)
        # Add context
        sentry_sdk.set_context("user_data", {
            "email": user_data.email,
            "operation": "create_user"
        })
        raise HTTPException(status_code=500, detail="Internal server error")
```

**Key Points:**
- ✅ Capture unexpected exceptions
- ❌ Don't capture expected business logic errors (400-level)
- ✅ Add context before capturing
- ✅ Still raise appropriate HTTP exceptions

### 2. Django View Error Handling

```python
from rest_framework import viewsets, status
from rest_framework.response import Response
import sentry_sdk

class UserViewSet(viewsets.ModelViewSet):
    def create(self, request):
        try:
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)

            user = user_service.create_user(serializer.validated_data)
            return Response(
                UserSerializer(user).data,
                status=status.HTTP_201_CREATED
            )

        except ValueError as e:
            # Business logic error - don't capture
            return Response(
                {"error": str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )

        except Exception as e:
            # Unexpected error - MUST capture
            sentry_sdk.capture_exception(e)
            sentry_sdk.set_context("request_data", {
                "method": request.method,
                "path": request.path,
                "user": request.user.id if request.user else None
            })

            return Response(
                {"error": "Internal server error"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
```

### 3. Service Layer Error Handling

```python
# services/user_service.py
import sentry_sdk

class UserService:
    async def create_user(self, user_data: UserCreate):
        """
        Create user with comprehensive error handling.
        """
        try:
            # Validate business rules
            if await self.repository.get_by_email(user_data.email):
                # Expected error - don't capture to Sentry
                raise ValueError("Email already exists")

            # Create user
            user = await self.repository.create(user_data)

            # Try to send email (non-critical)
            try:
                await email_service.send_welcome(user)
            except Exception as e:
                # Email failed - capture but don't fail the request
                sentry_sdk.capture_exception(e)
                sentry_sdk.capture_message(
                    "Welcome email failed",
                    level="warning"
                )

            return user

        except ValueError:
            # Business logic error - re-raise without capturing
            raise

        except Exception as e:
            # Unexpected error - capture and re-raise
            sentry_sdk.capture_exception(e)
            sentry_sdk.set_context("user_creation", {
                "email": user_data.email,
                "stage": "database_creation"
            })
            raise
```

---

## Performance Monitoring

### Custom Spans (FastAPI/Django)

```python
import sentry_sdk

async def complex_operation():
    with sentry_sdk.start_span(op="complex_operation") as span:
        # Database query
        with sentry_sdk.start_span(op="db.query", description="fetch users"):
            users = await db.execute(...)

        # External API call
        with sentry_sdk.start_span(op="http.client", description="call external API"):
            response = await httpx.get(...)

        # Heavy computation
        with sentry_sdk.start_span(op="compute", description="process data"):
            result = process_data(users, response)

        span.set_tag("users_count", len(users))
        span.set_data("result_size", len(result))

        return result
```

### Database Query Monitoring

```python
# SQLAlchemy - automatically tracked with integration
from sqlalchemy.ext.asyncio import create_async_engine
from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration

# Django - automatically tracked with integration
from sentry_sdk.integrations.django import DjangoIntegration

# Manual tracking if needed
with sentry_sdk.start_span(op="db.query", description="complex user query"):
    users = await session.execute(
        select(User)
        .join(Profile)
        .where(User.active == True)
        .options(selectinload(User.posts))
    )
```

---

## Background Tasks

### Celery Task Monitoring (Django)

```bash
pip install sentry-sdk[celery]
```

```python
# celery.py
import sentry_sdk
from sentry_sdk.integrations.celery import CeleryIntegration

sentry_sdk.init(
    dsn="your-sentry-dsn",
    integrations=[CeleryIntegration()],
)

# tasks.py
from celery import shared_task
import sentry_sdk

@shared_task
def process_user_data(user_id: int):
    try:
        with sentry_sdk.start_transaction(
            op="task",
            name="process_user_data"
        ):
            user = User.objects.get(id=user_id)
            # ... process user data
            return {"status": "success"}

    except User.DoesNotExist:
        # Expected error - don't capture
        return {"status": "error", "message": "User not found"}

    except Exception as e:
        # Unexpected error - capture and fail task
        sentry_sdk.capture_exception(e)
        sentry_sdk.set_context("task", {
            "task_name": "process_user_data",
            "user_id": user_id
        })
        raise  # Re-raise to retry task
```

### Async Background Tasks (FastAPI)

```python
import asyncio
import sentry_sdk

async def background_task(user_id: int):
    """Background task with Sentry tracking."""
    try:
        with sentry_sdk.start_transaction(
            op="background_task",
            name="send_notifications"
        ):
            user = await get_user(user_id)

            with sentry_sdk.start_span(op="notification", description="email"):
                await send_email(user)

            with sentry_sdk.start_span(op="notification", description="sms"):
                await send_sms(user)

    except Exception as e:
        sentry_sdk.capture_exception(e)
        sentry_sdk.set_context("background_task", {
            "task": "send_notifications",
            "user_id": user_id
        })
        # Don't re-raise in background tasks
```

---

## Context and Tags

### Adding Context

```python
import sentry_sdk

# Set user context
sentry_sdk.set_user({
    "id": user.id,
    "email": user.email,
    "username": user.username
})

# Set custom context
sentry_sdk.set_context("business_context", {
    "subscription_type": "premium",
    "account_age_days": 365,
    "feature_flags": ["new_ui", "beta_access"]
})

# Set tags for filtering
sentry_sdk.set_tag("environment", "production")
sentry_sdk.set_tag("api_version", "v2")
sentry_sdk.set_tag("feature", "user_registration")
```

### Breadcrumbs

```python
# Automatic breadcrumbs from integrations
# Manual breadcrumbs for debugging
sentry_sdk.add_breadcrumb(
    category="auth",
    message="User attempted login",
    level="info",
    data={"username": username}
)

sentry_sdk.add_breadcrumb(
    category="database",
    message="Query executed",
    level="info",
    data={"query_time_ms": 150, "rows": 42}
)
```

---

## Exception Filtering

```python
from sentry_sdk.integrations.logging import ignore_logger

# Initialize Sentry
sentry_sdk.init(
    dsn="your-sentry-dsn",
    # Ignore specific exceptions
    ignore_errors=[
        KeyboardInterrupt,
        BrokenPipeError,
    ],
    # Filter events before sending
    before_send=filter_events,
)

def filter_events(event, hint):
    """Filter events before sending to Sentry."""
    # Don't capture 404 errors
    if "exception" in event:
        exc_type = event["exception"]["values"][0]["type"]
        if exc_type == "Http404":
            return None

    # Don't capture health check errors
    if "request" in event:
        url = event["request"].get("url", "")
        if "/health" in url:
            return None

    return event
```

---

## Best Practices

### ✅ DO

```python
# ✅ Capture unexpected exceptions
try:
    result = dangerous_operation()
except Exception as e:
    sentry_sdk.capture_exception(e)
    raise

# ✅ Add context before capturing
sentry_sdk.set_context("operation", {"type": "payment", "amount": 100})
sentry_sdk.capture_exception(e)

# ✅ Use appropriate log levels
sentry_sdk.capture_message("High memory usage", level="warning")

# ✅ Track performance-critical sections
with sentry_sdk.start_span(op="expensive_operation"):
    result = expensive_operation()
```

### ❌ DON'T

```python
# ❌ Don't capture expected business errors
try:
    validate_user_input(data)
except ValidationError as e:
    sentry_sdk.capture_exception(e)  # DON'T!
    # These are expected, use logging instead

# ❌ Don't use print() for errors
except Exception as e:
    print(f"Error: {e}")  # DON'T!
    # Always capture to Sentry

# ❌ Don't capture and swallow
try:
    operation()
except Exception as e:
    sentry_sdk.capture_exception(e)
    pass  # DON'T! Re-raise or handle properly

# ❌ Don't forget to add context
sentry_sdk.capture_exception(e)  # Missing context!
```

---

## Testing

### Testing Sentry Integration

```python
# FastAPI test
def test_endpoint_error_handling(client):
    with patch('sentry_sdk.capture_exception') as mock_capture:
        response = client.post("/users", json={"invalid": "data"})
        assert response.status_code == 500
        mock_capture.assert_called_once()

# Django test
from unittest.mock import patch

class UserViewTest(TestCase):
    @patch('sentry_sdk.capture_exception')
    def test_unexpected_error_captured(self, mock_capture):
        # Trigger error
        response = self.client.post('/users/', data={})

        # Assert Sentry was called
        self.assertEqual(response.status_code, 500)
        mock_capture.assert_called_once()
```

### Manual Testing

```python
# Test Sentry connection
def test_sentry():
    try:
        1 / 0
    except Exception as e:
        sentry_sdk.capture_exception(e)
        print("Test exception sent to Sentry. Check your dashboard.")
```

---

## Environment Configuration

### .env File

```bash
# Sentry Configuration
SENTRY_DSN=https://your-key@sentry.io/project-id
SENTRY_ENVIRONMENT=production  # or development, staging
SENTRY_TRACES_SAMPLE_RATE=1.0  # 1.0 = 100% (adjust for production)
SENTRY_PROFILES_SAMPLE_RATE=1.0
```

### Different Environments

```python
import os
from pydantic import BaseSettings

class Settings(BaseSettings):
    SENTRY_DSN: str
    SENTRY_ENVIRONMENT: str = "development"
    SENTRY_TRACES_SAMPLE_RATE: float = 1.0

    # Lower sample rate in production
    @property
    def sentry_traces_rate(self):
        return 0.1 if self.SENTRY_ENVIRONMENT == "production" else 1.0

settings = Settings()

sentry_sdk.init(
    dsn=settings.SENTRY_DSN,
    environment=settings.SENTRY_ENVIRONMENT,
    traces_sample_rate=settings.sentry_traces_rate,
)
```

---

## Migration Checklist

If migrating from print/logging to Sentry:

- [ ] Install sentry-sdk with appropriate integrations
- [ ] Initialize Sentry at app entry point (FIRST import)
- [ ] Replace all `print(error)` with `sentry_sdk.capture_exception()`
- [ ] Replace critical `logger.error()` with Sentry captures
- [ ] Add context to all exception captures
- [ ] Implement error handling in all views/endpoints
- [ ] Add performance spans to critical operations
- [ ] Configure background task monitoring (Celery/async)
- [ ] Set up environment-specific configuration
- [ ] Test Sentry integration
- [ ] Set up alerts in Sentry dashboard

---

## Key Takeaways

1. **ALL unexpected errors must go to Sentry** - no exceptions
2. **Add context** - makes debugging 10x easier
3. **Don't capture expected errors** - only unexpected exceptions
4. **Use performance monitoring** - track slow operations
5. **Initialize early** - Sentry init should be first import
6. **Environment-specific config** - different sample rates per environment
7. **Test your integration** - ensure errors actually reach Sentry
