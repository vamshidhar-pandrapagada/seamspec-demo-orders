import logging
from decimal import Decimal

import pytest

from orders.service import CheckoutRequest, LineItem, PaymentDeclined, Store, checkout

CARD = "4242424242424242"


@pytest.mark.parametrize("card", [CARD, "4000000000000002"])
def test_debug_logs_show_a_card_only_as_its_last_four_digits(caplog, card):
    caplog.set_level(logging.DEBUG)
    request = CheckoutRequest("cus_1", "ada@example.com", card, (LineItem("sku_book", 1, Decimal("9.99")),))
    try:
        checkout(Store(), request)
    except PaymentDeclined:
        pass
    logged = "\n".join(record.getMessage() for record in caplog.records)
    assert f"****{card[-4:]}" in logged
    assert card not in logged
