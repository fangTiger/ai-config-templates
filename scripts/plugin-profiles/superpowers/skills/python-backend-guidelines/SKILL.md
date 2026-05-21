---
name: python-backend-guidelines
description: Backend development guidelines for Python/Django/FastAPI. Covers layered architecture, API design, async patterns, database access (SQLAlchemy/Django ORM), Pydantic validation, error handling with Sentry, and Python best practices. Use when creating routes, views, services, repositories, middleware, or working with Python backend frameworks.
---

# Python Backend Development Guidelines

## Purpose

Establish consistency and best practices for Python backend development using Django REST Framework or FastAPI with modern Python patterns.

## When to Use This Skill

Automatically activates when working on:
- Creating or modifying API routes/endpoints
- Building views/controllers, services, repositories
- Database operations with SQLAlchemy or Django ORM
- Request validation with Pydantic
- Async/await patterns (FastAPI)
- Error tracking with Sentry
- Middleware and authentication
- Backend testing and refactoring

---

## Quick Start

### New Backend Feature Checklist

- [ ] **Route/View**: Clean API definition
- [ ] **Validation**: Pydantic schema (FastAPI) or Serializer (Django)
- [ ] **Service**: Business logic with dependency injection
- [ ] **Repository**: Database access layer (optional for complex queries)
- [ ] **Error Handling**: Proper exception handling + Sentry
- [ ] **Tests**: Unit + integration tests
- [ ] **Documentation**: OpenAPI/Swagger (FastAPI auto-gen)

---

## Architecture Overview

### Layered Architecture

```
HTTP Request
    ↓
Routes/URLs (routing only)
    ↓
Views/Endpoints (request handling)
    ↓
Services (business logic)
    ↓
Repositories (data access - optional)
    ↓
ORM (SQLAlchemy/Django ORM)
    ↓
Database
```

**Key Principle:** Separation of concerns - each layer has ONE responsibility.

---

## Directory Structure

### FastAPI Project

```
app/
├── api/
│   ├── v1/
│   │   ├── endpoints/       # Route handlers
│   │   └── dependencies.py  # DI dependencies
│   └── deps.py
├── core/
│   ├── config.py           # Settings (Pydantic BaseSettings)
│   ├── security.py         # Auth utilities
│   └── logging.py          # Logging config
├── models/                 # SQLAlchemy models
├── schemas/                # Pydantic schemas
├── services/               # Business logic
├── repositories/           # Data access (optional)
├── crud/                   # CRUD operations
├── db/
│   ├── base.py
│   └── session.py
├── middleware/             # Custom middleware
├── tests/
├── main.py                 # FastAPI app
└── __init__.py
```

### Django REST Framework Project

```
project/
├── apps/
│   ├── users/
│   │   ├── models.py       # Django models
│   │   ├── serializers.py  # DRF serializers
│   │   ├── views.py        # API views
│   │   ├── services.py     # Business logic
│   │   ├── urls.py         # URL routing
│   │   └── tests/
│   └── ...
├── core/
│   ├── settings/           # Django settings
│   ├── middleware.py       # Custom middleware
│   └── exceptions.py       # Exception handlers
├── config/
│   ├── urls.py
│   └── wsgi.py/asgi.py
└── manage.py
```

---

## Core Patterns

### 1. FastAPI Endpoint Pattern

```python
from fastapi import APIRouter, Depends, HTTPException
from app.schemas import UserCreate, UserResponse
from app.services import user_service
from app.api.deps import get_current_user

router = APIRouter()

@router.post("/users", response_model=UserResponse)
async def create_user(
    user_in: UserCreate,
    current_user = Depends(get_current_user)
):
    """
    Create new user (requires authentication).
    """
    try:
        user = await user_service.create_user(user_in)
        return user
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
```

**Key Points:**
- Use Pydantic models for validation
- Dependency injection for auth, DB sessions
- Async/await for I/O operations
- Type hints everywhere
- Proper HTTP status codes

### 2. Django REST Framework View Pattern

```python
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import User
from .serializers import UserSerializer
from .services import user_service

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def create(self, request):
        """Create new user."""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            user = user_service.create_user(serializer.validated_data)
            return Response(
                UserSerializer(user).data,
                status=status.HTTP_201_CREATED
            )
        except ValueError as e:
            return Response(
                {"error": str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )
```

### 3. Service Layer Pattern

```python
# services/user_service.py
from typing import Optional
from app.models import User
from app.schemas import UserCreate
from app.repositories import user_repository
import sentry_sdk

class UserService:
    """Business logic for user operations."""

    def __init__(self, repository=None):
        self.repository = repository or user_repository

    async def create_user(self, user_data: UserCreate) -> User:
        """
        Create user with business logic validation.

        Args:
            user_data: User creation data

        Returns:
            Created user instance

        Raises:
            ValueError: If validation fails
        """
        try:
            # Business logic validation
            if await self.repository.get_by_email(user_data.email):
                raise ValueError("Email already registered")

            # Create user
            user = await self.repository.create(user_data)

            # Additional business logic (e.g., send welcome email)
            # await email_service.send_welcome(user)

            return user

        except Exception as e:
            sentry_sdk.capture_exception(e)
            raise

# Singleton instance
user_service = UserService()
```

**Service Layer Guidelines:**
- Pure business logic (no HTTP concerns)
- Dependency injection for repositories
- Comprehensive error handling
- Sentry integration for exceptions
- Async support when needed
- Testable with mocks

### 4. Repository Pattern (Optional)

```python
# repositories/user_repository.py
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models import User
from app.schemas import UserCreate

class UserRepository:
    """Data access layer for User model."""

    def __init__(self, session: AsyncSession):
        self.session = session

    async def create(self, user_data: UserCreate) -> User:
        """Create new user in database."""
        user = User(**user_data.dict())
        self.session.add(user)
        await self.session.commit()
        await self.session.refresh(user)
        return user

    async def get_by_id(self, user_id: int) -> Optional[User]:
        """Get user by ID."""
        result = await self.session.execute(
            select(User).where(User.id == user_id)
        )
        return result.scalar_one_or_none()

    async def get_by_email(self, email: str) -> Optional[User]:
        """Get user by email."""
        result = await self.session.execute(
            select(User).where(User.email == email)
        )
        return result.scalar_one_or_none()

    async def list(self, skip: int = 0, limit: int = 100) -> List[User]:
        """List users with pagination."""
        result = await self.session.execute(
            select(User).offset(skip).limit(limit)
        )
        return result.scalars().all()

# Dependency injection
async def get_user_repository(
    session: AsyncSession = Depends(get_db_session)
) -> UserRepository:
    return UserRepository(session)
```

---

## Best Practices

### Type Hints

```python
from typing import List, Optional, Dict, Any
from pydantic import BaseModel

# Always use type hints
def process_users(
    users: List[User],
    filters: Optional[Dict[str, Any]] = None
) -> List[Dict[str, Any]]:
    """Process users with optional filters."""
    ...
```

### Pydantic Validation (FastAPI)

```python
from pydantic import BaseModel, EmailStr, validator, Field

class UserCreate(BaseModel):
    email: EmailStr
    username: str = Field(..., min_length=3, max_length=50)
    password: str = Field(..., min_length=8)
    age: Optional[int] = Field(None, ge=0, le=150)

    @validator('username')
    def username_alphanumeric(cls, v):
        assert v.isalnum(), 'must be alphanumeric'
        return v

    class Config:
        # Configuration
        str_strip_whitespace = True
```

### Error Handling with Sentry

```python
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration

# Initialize Sentry (in main.py or settings)
sentry_sdk.init(
    dsn="your-sentry-dsn",
    integrations=[FastApiIntegration()],
    traces_sample_rate=1.0,
)

# In your code
try:
    result = await some_operation()
except Exception as e:
    # Sentry automatically captures
    sentry_sdk.capture_exception(e)
    # Add context
    sentry_sdk.set_context("operation", {"type": "user_creation"})
    raise
```

### Async/Await Best Practices

```python
# Good: Concurrent operations
async def get_user_data(user_id: int):
    profile, posts, stats = await asyncio.gather(
        get_profile(user_id),
        get_posts(user_id),
        get_stats(user_id)
    )
    return {"profile": profile, "posts": posts, "stats": stats}

# Good: Use async context managers
async def process_with_session():
    async with get_db_session() as session:
        user = await session.execute(...)
        return user

# Avoid: Mixing sync/async unnecessarily
# Use sync functions for CPU-bound, async for I/O-bound
```

### Database Migrations

**Alembic (with SQLAlchemy/FastAPI):**
```bash
# Create migration
alembic revision --autogenerate -m "Add user table"

# Apply migrations
alembic upgrade head

# Rollback
alembic downgrade -1
```

**Django:**
```bash
# Create migrations
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Rollback
python manage.py migrate app_name 0001
```

---

## Testing Patterns

### FastAPI Test Example

```python
import pytest
from httpx import AsyncClient
from app.main import app
from app.tests.utils import create_test_user

@pytest.mark.asyncio
async def test_create_user():
    async with AsyncClient(app=app, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/users",
            json={
                "email": "test@example.com",
                "username": "testuser",
                "password": "securepass123"
            }
        )

    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "test@example.com"
    assert "id" in data

@pytest.mark.asyncio
async def test_service_layer():
    """Test service in isolation."""
    mock_repo = Mock()
    mock_repo.get_by_email.return_value = None

    service = UserService(repository=mock_repo)
    user = await service.create_user(UserCreate(...))

    assert user.email == "test@example.com"
    mock_repo.create.assert_called_once()
```

---

## Configuration Management

### FastAPI with Pydantic Settings

```python
from pydantic import BaseSettings, PostgresDsn

class Settings(BaseSettings):
    PROJECT_NAME: str = "My API"
    API_V1_STR: str = "/api/v1"

    DATABASE_URL: PostgresDsn
    SECRET_KEY: str

    SENTRY_DSN: Optional[str] = None

    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
```

### Django Settings

```python
# settings/base.py
from pathlib import Path
import os

BASE_DIR = Path(__file__).resolve().parent.parent

# Use environment variables
SECRET_KEY = os.environ.get('SECRET_KEY')
DEBUG = os.environ.get('DEBUG', 'False') == 'True'

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME'),
        'USER': os.environ.get('DB_USER'),
        'PASSWORD': os.environ.get('DB_PASSWORD'),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}
```

---

## Performance Optimization

### Database Query Optimization

```python
# Bad: N+1 queries
users = await session.execute(select(User))
for user in users.scalars():
    posts = await get_user_posts(user.id)  # N queries!

# Good: Eager loading
from sqlalchemy.orm import selectinload

users = await session.execute(
    select(User).options(selectinload(User.posts))
)
for user in users.scalars():
    posts = user.posts  # Already loaded
```

### Caching

```python
from fastapi_cache import FastAPICache
from fastapi_cache.backends.redis import RedisBackend
from fastapi_cache.decorator import cache

@router.get("/users/{user_id}")
@cache(expire=60)  # Cache for 60 seconds
async def get_user(user_id: int):
    return await user_service.get_user(user_id)
```

---

## Security Best Practices

```python
from passlib.context import CryptContext
from jose import JWTError, jwt

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

# JWT tokens
def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
```

---

## Comparison: Django vs FastAPI

| Feature | Django REST Framework | FastAPI |
|---------|----------------------|---------|
| **Performance** | Sync (good) | Async (excellent) |
| **Learning Curve** | Steeper | Gentler |
| **Validation** | Serializers | Pydantic |
| **Documentation** | Manual/drf-yasg | Auto (OpenAPI) |
| **Admin Panel** | ✅ Built-in | ❌ None |
| **ORM** | Django ORM | SQLAlchemy/Tortoise |
| **Use Case** | Full-featured apps | APIs, microservices |

---

## Next Steps

- Review [Python Type Hints](https://docs.python.org/3/library/typing.html)
- Learn [Pydantic](https://pydantic-docs.helpmanual.io/)
- Study [FastAPI](https://fastapi.tiangolo.com/) or [DRF](https://www.django-rest-framework.org/)
- Implement [Sentry](https://docs.sentry.io/platforms/python/) error tracking
- Setup database migrations with Alembic or Django migrations

---

## Key Takeaways

1. **Layered Architecture** - Separate concerns (routes → views → services → repositories)
2. **Type Hints** - Use them everywhere for better IDE support and catching bugs
3. **Pydantic/Serializers** - Let frameworks handle validation
4. **Async When Needed** - Use async for I/O-bound operations (FastAPI)
5. **Service Layer** - Keep business logic separate from request handling
6. **Error Tracking** - Integrate Sentry from day one
7. **Testing** - Write tests at service layer for better coverage
8. **Configuration** - Use environment variables, never hardcode secrets
