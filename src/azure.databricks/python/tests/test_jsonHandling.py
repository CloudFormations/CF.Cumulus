import pytest
from notebooks.ingest.utils.CreateMergeQuery import format_nested


def test_non_nested_call_default():
    expected = None
    actual = format_nested("my_col", "string", "", "")
    assert expected == actual

def test_nested_timestamp():
    expected = "to_timestamp(nested.field,'yyyy-MM-dd') as my_col"
    actual = format_nested("my_col", "timestamp", "yyyy-MM-dd", "nested.field")
    assert expected == actual

def test_nested_date():
    expected = "to_date(nested.date,'dd/MM/yyyy') as my_col"
    actual = format_nested("my_col", "date", "dd/MM/yyyy", "nested.date")
    assert expected == actual

def test_nested_other_type_casts():
    expected = "cast(nested.value as int) as my_col"
    actual = format_nested("my_col", "int", "", "nested.value")
    assert expected == actual

