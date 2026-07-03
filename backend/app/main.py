from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.routers import (
    auth,
    bookings,
    carriers,
    clients,
    hotels,
    payments,
    reports,
    staff,
    tours,
)

app = FastAPI(title="Travel Agency API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(staff.router)
app.include_router(hotels.router)
app.include_router(carriers.router)
app.include_router(clients.router)
app.include_router(tours.router)
app.include_router(bookings.router)
app.include_router(payments.router)
app.include_router(reports.router)


@app.get("/")
async def root():
    return {"status": "ok", "service": "Travel Agency API"}
