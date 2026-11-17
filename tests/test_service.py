from decimal import Decimal

import pytest

from orders.service import (
    CheckoutRequest,
    LineItem,
    PaymentDeclined,
    Store,
    checkout,
    get_order,
    issue_reset_token,
    list_orders,
    reset_password,
)


def request(customer_id: str = "cus_1", card: str = "4242424242424242") -> CheckoutRequest:
    return CheckoutRequest(
        customer_id=customer_id,
        email="ada@example.com",
        card_number=card,
        items=(LineItem("sku_book", 2, Decimal("9.99")), LineItem("sku_pen", 1, Decimal("1.50"))),
    )


def test_checkout_totals_the_items_and_keeps_only_the_last_four_digits():
    order = checkout(Store(), request())
    assert order.total == Decimal("21.48")
    assert order.card_last4 == "4242"


def test_a_declined_card_creates_no_order():
    store = Store()
    with pytest.raises(PaymentDeclined):
        checkout(store, request(card="4000000000000002"))
    assert store.orders == {}


def test_an_empty_order_is_refused():
    with pytest.raises(ValueError):
        checkout(Store(), CheckoutRequest("cus_1", "ada@example.com", "4242424242424242", ()))


def test_orders_are_listed_and_found_by_customer():
    store = Store()
    order = checkout(store, request())
    assert list_orders(store, "cus_1") == [order]
    assert get_order(store, "cus_1", order.id) == order


def test_a_reset_token_sets_the_password():
    store = Store()
    reset_password(store, issue_reset_token(store, "ada@example.com"), "correct horse")
    assert store.passwords["ada@example.com"] == "correct horse"
