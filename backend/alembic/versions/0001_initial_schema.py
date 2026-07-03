"""initial schema

Revision ID: 0001
Revises:
Create Date: 2026-07-02

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "0001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "hotels",
        sa.Column("hotel_id", sa.Integer(), sa.Identity(), primary_key=True),
        sa.Column("hotel_name", sa.String(100), nullable=False),
        sa.Column("country", sa.String(50), nullable=False),
        sa.Column("city", sa.String(50), nullable=False),
        sa.Column("address", sa.String(150)),
        sa.Column("category", sa.String(20)),
        sa.Column("star_rating", sa.SmallInteger()),
        sa.Column("phone", sa.String(20)),
        sa.Column("email", sa.String(100)),
        sa.Column("night_price", sa.Numeric(10, 2), nullable=False),
        sa.Column("notes", sa.Text()),
        sa.CheckConstraint("star_rating BETWEEN 1 AND 5", name="chk_star_rating"),
    )

    op.create_table(
        "carriers",
        sa.Column("carrier_id", sa.Integer(), sa.Identity(), primary_key=True),
        sa.Column("company_name", sa.String(100), nullable=False),
        sa.Column("transport_type", sa.String(30), nullable=False),
        sa.Column("contact_person", sa.String(100)),
        sa.Column("phone", sa.String(20)),
        sa.Column("email", sa.String(100)),
        sa.Column("address", sa.String(150)),
        sa.Column("trip_cost", sa.Numeric(10, 2), nullable=False),
        sa.Column("schedule", sa.String(100)),
        sa.Column("notes", sa.Text()),
    )

    op.create_table(
        "clients",
        sa.Column("client_id", sa.Integer(), sa.Identity(), primary_key=True),
        sa.Column("last_name", sa.String(50), nullable=False),
        sa.Column("first_name", sa.String(50), nullable=False),
        sa.Column("middle_name", sa.String(50)),
        sa.Column("birth_date", sa.Date()),
        sa.Column("phone", sa.String(20)),
        sa.Column("email", sa.String(100)),
        sa.Column("address", sa.String(150)),
        sa.Column("passport", sa.String(30)),
        sa.Column("foreign_passport", sa.String(30)),
        sa.Column("notes", sa.Text()),
    )

    op.create_table(
        "tours",
        sa.Column("tour_id", sa.Integer(), sa.Identity(), primary_key=True),
        sa.Column("tour_name", sa.String(100), nullable=False),
        sa.Column("country", sa.String(50), nullable=False),
        sa.Column("city", sa.String(50), nullable=False),
        sa.Column("start_date", sa.Date(), nullable=False),
        sa.Column("end_date", sa.Date(), nullable=False),
        sa.Column("base_price", sa.Numeric(10, 2), nullable=False),
        sa.Column("hotel_id", sa.Integer(), sa.ForeignKey("hotels.hotel_id"), nullable=False),
        sa.Column("carrier_id", sa.Integer(), sa.ForeignKey("carriers.carrier_id"), nullable=False),
        sa.Column("notes", sa.Text()),
        sa.CheckConstraint("end_date > start_date", name="chk_dates"),
    )
    op.execute(
        "ALTER TABLE tours ADD COLUMN duration_days INT "
        "GENERATED ALWAYS AS (end_date - start_date) STORED"
    )

    op.create_table(
        "bookings",
        sa.Column("booking_id", sa.Integer(), sa.Identity(), primary_key=True),
        sa.Column("client_id", sa.Integer(), sa.ForeignKey("clients.client_id"), nullable=False),
        sa.Column("tour_id", sa.Integer(), sa.ForeignKey("tours.tour_id"), nullable=False),
        sa.Column("booking_date", sa.Date(), nullable=False, server_default=sa.text("CURRENT_DATE")),
        sa.Column("people_count", sa.Integer(), nullable=False),
        sa.Column("discount_percent", sa.Numeric(4, 2), server_default="0"),
        sa.Column("commission_percent", sa.Numeric(4, 2), server_default="10"),
        sa.Column("total_cost", sa.Numeric(10, 2), nullable=False),
        sa.Column("status", sa.String(20), server_default="оформлен"),
        sa.Column("notes", sa.Text()),
        sa.CheckConstraint("people_count > 0", name="chk_people_count"),
    )

    op.create_table(
        "payments",
        sa.Column("payment_id", sa.Integer(), sa.Identity(), primary_key=True),
        sa.Column("booking_id", sa.Integer(), sa.ForeignKey("bookings.booking_id"), nullable=False),
        sa.Column("payment_date", sa.Date(), nullable=False, server_default=sa.text("CURRENT_DATE")),
        sa.Column("amount", sa.Numeric(10, 2), nullable=False),
        sa.Column("payment_method", sa.String(30)),
        sa.Column("notes", sa.Text()),
    )

    op.create_index("idx_tours_country", "tours", ["country"])
    op.create_index("idx_tours_dates", "tours", ["start_date", "end_date"])
    op.create_index("idx_clients_lastname", "clients", ["last_name"])
    op.create_index("idx_bookings_date", "bookings", ["booking_date"])


def downgrade() -> None:
    op.drop_table("payments")
    op.drop_table("bookings")
    op.drop_table("tours")
    op.drop_table("clients")
    op.drop_table("carriers")
    op.drop_table("hotels")
