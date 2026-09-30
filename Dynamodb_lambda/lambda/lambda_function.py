import json
import os
from decimal import Decimal

import boto3
from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Key

TABLE_NAME = os.getenv("TABLE_NAME")

if not TABLE_NAME:
    raise RuntimeError("TABLE_NAME environment variable not configured")

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)


def lambda_handler(event, context):

    action = event.get("action")

    try:

        if action == "get":
            return get_order(event)

        elif action == "query":
            return query_orders(event)

        elif action == "create":
            return create_order(event)

        elif action == "scan":
            return scan_orders()

        else:
            return response(
                400,
                {"error": f"Unsupported action: {action}"}
            )

    except KeyError as e:

        return response(
            400,
            {"error": f"Missing required field: {str(e)}"}
        )

    except ClientError as e:

        return response(
            500,
            {
                "error": e.response["Error"]["Message"]
            }
        )

    except Exception as e:

        return response(
            500,
            {"error": str(e)}
        )


def get_order(event):

    customer_id = event["customer_id"]
    order_date = event["order_date"]

    result = table.get_item(
        Key={
            "customer_id": customer_id,
            "order_date": order_date
        }
    )

    item = result.get("Item")

    if not item:

        return response(
            404,
            {"error": "Order not found"}
        )

    return response(200, item)


def query_orders(event):

    customer_id = event["customer_id"]
    date_prefix = event.get("date_prefix")

    if date_prefix:

        result = table.query(
            KeyConditionExpression=
            Key("customer_id").eq(customer_id) &
            Key("order_date").begins_with(date_prefix)
        )

    else:

        result = table.query(
            KeyConditionExpression=
            Key("customer_id").eq(customer_id)
        )

    return response(
        200,
        {
            "count": result["Count"],
            "orders": result["Items"]
        }
    )


def create_order(event):

    if "item" not in event:

        return response(
            400,
            {"error": "item is required"}
        )

    item = convert_numbers(event["item"])

    if "customer_id" not in item:

        return response(
            400,
            {"error": "customer_id is required"}
        )

    if "order_date" not in item:

        return response(
            400,
            {"error": "order_date is required"}
        )

    table.put_item(
        Item=item,
        ConditionExpression=
        "attribute_not_exists(customer_id) AND attribute_not_exists(order_date)"
    )

    return response(
        201,
        {
            "message": "Order created",
            "item": item
        }
    )


def scan_orders():

    result = table.scan(
        Limit=50
    )

    return response(
        200,
        {
            "count": result["Count"],
            "orders": result["Items"]
        }
    )


def convert_numbers(data):

    return json.loads(
        json.dumps(data),
        parse_float=Decimal
    )


def response(status_code, body):

    return {
        "statusCode": status_code,
        "body": json.dumps(
            body,
            default=str
        )
    }