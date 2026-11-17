"""Checkout, order lookup and password resets, kept in memory so the demo runs anywhere."""

from __future__ import annotations

import logging
import secrets
from dataclasses import dataclass, field
from decimal import Decimal

log = logging.getLogger("orders")

DECLINED_PREFIX = "4000"  # test cards starting with this are declined by the payment provider


class PaymentDeclined(Exception):
    pass


class NotFound(Exception):
    pass


class InvalidToken(Exception):
    pass


@dataclass(frozen=True)
class LineItem:
    sku: str
    quantity: int
    unit_price: Decimal


@dataclass(frozen=True)
class CheckoutRequest:
    customer_id: str
    email: str
    card_number: str
    items: tuple[LineItem, ...]


@dataclass(frozen=True)
class Order:
    id: str
    customer_id: str
    total: Decimal
    card_last4: str


@dataclass
class Store:
    orders: dict[str, Order] = field(default_factory=dict)
    reset_tokens: dict[str, str] = field(default_factory=dict)  # token -> email
    passwords: dict[str, str] = field(default_factory=dict)  # email -> password


def checkout(store: Store, request: CheckoutRequest) -> Order:
    """Charge the card and record the order."""
    if not request.items:
        raise ValueError("an order needs at least one item")
    total = sum((item.unit_price * item.quantity for item in request.items), Decimal("0"))
    if request.card_number.startswith(DECLINED_PREFIX):
        log.warning("payment declined for customer %s", request.customer_id)
        raise PaymentDeclined("card declined")
    order = Order(
        id=f"ord_{secrets.token_hex(4)}",
        customer_id=request.customer_id,
        total=total,
        card_last4=request.card_number[-4:],
    )
    store.orders[order.id] = order
    log.info("order %s created for customer %s", order.id, request.customer_id)
    return order


def list_orders(store: Store, customer_id: str) -> list[Order]:
    """The orders of one customer."""
    return [order for order in store.orders.values() if order.customer_id == customer_id]


def get_order(store: Store, customer_id: str, order_id: str) -> Order:
    """One order, only if it belongs to this customer."""
    order = store.orders.get(order_id)
    if order is None or order.customer_id != customer_id:
        raise NotFound(order_id)
    return order


def issue_reset_token(store: Store, email: str) -> str:
    """A token the customer gets by email to choose a new password."""
    token = secrets.token_urlsafe(16)
    store.reset_tokens[token] = email
    return token


def reset_password(store: Store, token: str, new_password: str) -> None:
    """Set a new password with a reset token."""
    email = store.reset_tokens.pop(token, None)
    if email is None:
        raise InvalidToken("unknown or used token")
    store.passwords[email] = new_password
