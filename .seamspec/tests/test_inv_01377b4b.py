import pytest

from orders.service import InvalidToken, Store, issue_reset_token, reset_password


def test_a_password_reset_token_works_only_once():
    store = Store()
    token = issue_reset_token(store, "ada@example.com")
    reset_password(store, token, "first new password")
    with pytest.raises(InvalidToken):
        reset_password(store, token, "second new password")
    assert store.passwords["ada@example.com"] == "first new password"


def test_a_made_up_token_is_refused():
    store = Store()
    with pytest.raises(InvalidToken):
        reset_password(store, "not-a-real-token", "new password")
