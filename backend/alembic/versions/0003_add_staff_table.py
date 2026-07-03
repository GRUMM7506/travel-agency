"""add staff table

Revision ID: 0003
Revises: 0002
Create Date: 2026-07-04 17:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '0003'
down_revision = '0002'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'staff',
        sa.Column('staff_id', sa.Integer(), primary_key=True),
        sa.Column('full_name', sa.String(100), nullable=False),
        sa.Column('email', sa.String(100), nullable=False),
        sa.Column('password_hash', sa.String(255), nullable=False),
        sa.Column('role', sa.String(20), nullable=False, server_default='manager'),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default=sa.true()),
    )
    op.create_unique_constraint('uq_staff_email', 'staff', ['email'])
    op.create_index('ix_staff_email', 'staff', ['email'])


def downgrade():
    op.drop_index('ix_staff_email', table_name='staff')
    op.drop_constraint('uq_staff_email', 'staff', type_='unique')
    op.drop_table('staff')
