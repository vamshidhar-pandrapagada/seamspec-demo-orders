from decimal import Decimal

import pytest

from orders.service import CheckoutRequest, LineItem, NotFound, Store, checkout, get_order, list_orders


def order_for(store, customer_id):
    item = (LineItem("sku_book", 1, Decimal("9.99")),)
    return checkout(store, CheckoutRequest(customer_id, f"{customer_id}@example.com", "4242424242424242", item))


def test_a_customer_never_sees_another_customers_orders():
    store = Store()
    mine = order_for(store, "cus_a")
    theirs = order_for(store, "cus_b")
    assert [order.id for order in list_orders(store, "cus_a")] == [mine.id]
