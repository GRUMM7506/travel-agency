"""add image_url to entities

Revision ID: 0002
Revises: 0001
Create Date: 2026-07-04 11:57:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '0002'
down_revision = '0001'
branch_labels = None
depends_on = None


def upgrade():
    # Добавляем колонку image_url в таблицы hotels, carriers, tours
    op.add_column('hotels', sa.Column('image_url', sa.String(500), nullable=True))
    op.add_column('carriers', sa.Column('image_url', sa.String(500), nullable=True))
    op.add_column('tours', sa.Column('image_url', sa.String(500), nullable=True))


def downgrade():
    # Удаляем колонку image_url
    op.drop_column('hotels', 'image_url')
    op.drop_column('carriers', 'image_url')
    op.drop_column('tours', 'image_url')