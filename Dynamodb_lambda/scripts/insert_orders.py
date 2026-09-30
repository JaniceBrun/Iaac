#!/usr/bin/env python3
import json
import os
from decimal import Decimal
from pathlib import Path

import boto3


def parse_args():
    import argparse

    parser = argparse.ArgumentParser(
        description="Insert sample orders into a DynamoDB table. Requires --insert."
    )
    parser.add_argument(
        "--insert",
        action="store_true",
        help="Actually insert the items into DynamoDB. This flag is required.",
    )
    parser.add_argument(
        "--table-name",
        default=os.getenv("TABLE_NAME"),
        help="DynamoDB table name. Set via --table-name or TABLE_NAME.",
    )
    parser.add_argument(
        "--file",
        type=str,
        default=str(Path(__file__).resolve().parents[1] / "data" / "orders.json"),
        help="Path to a JSON file containing a list of orders.",
    )
    return parser.parse_args()


def load_orders(path: str):
    if not path:
        raise ValueError("Data file path is required.")

    if not Path(path).exists():
        raise FileNotFoundError(f"Data file not found: {path}")

    with open(path, "r", encoding="utf-8") as f:
        payload = json.load(f)

    if not isinstance(payload, list):
        raise ValueError("The file must contain a JSON list of order objects.")

    return payload


def normalize_item(item):
    return {
        "customer_id": str(item["customer_id"]),
        "order_date": str(item["order_date"]),
        "product": str(item["product"]),
        "quantity": Decimal(str(item["quantity"])),
        "total": Decimal(str(item["total"])),
    }


def insert_orders(table_name: str, file_path: str):
    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(table_name)

    for raw_item in load_orders(file_path):
        table.put_item(Item=normalize_item(raw_item))

    print(f"Inserted {len(load_orders(file_path))} items into {table_name}")


def main():
    args = parse_args()

    if not args.table_name:
        raise SystemExit(
            "Missing table name. Use --table-name or set TABLE_NAME."
        )

    if not args.insert and os.getenv("INSERT", "").lower() not in {"1", "true", "yes", "y"}:
        raise SystemExit(
            "No insert requested. Use --insert or set INSERT=true to insert records."
        )

    insert_orders(args.table_name, args.file)


if __name__ == "__main__":
    main()
