import logging
from decimal import Decimal

import pytest

from orders.service import CheckoutRequest, LineItem, PaymentDeclined, Store, checkout

EMAIL = "ada.lovelace@example.com"
APPROVED = "4242424242424242"
DECLINED = "4000000000000002"


@pytest.mark.parametrize("card", [APPROVED, DECLINED])
def test_checkout_never_logs_the_email_or_the_card_number(caplog, card):
    caplog.set_level(logging.DEBUG)
    request = CheckoutRequest("cus_1", EMAIL, card, (LineItem("sku_book", 1, Decimal("9.99")),))
    try:
        checkout(Store(), request)
    except PaymentDeclined:
        pass
    logged = "\n".join(record.getMessage() for record in caplog.records)
    assert caplog.records, "checkout should log what it does"
    assert EMAIL not in logged
    assert card not in logged
