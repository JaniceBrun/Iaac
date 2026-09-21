import os

VALID_TOKEN = os.environ["AUTH_TOKEN"]


def _policy(principal, effect, arn):
    return {
        "principalId": principal,
        "policyDocument": {
            "Version": "2012-10-17",
            "Statement": [{"Action": "execute-api:Invoke", "Effect": effect, "Resource": arn}],
        },
    }


def handler(event, context):
    token = event.get("authorizationToken", "")
    method_arn = event["methodArn"]

    if token == f"Bearer {VALID_TOKEN}":
        return _policy("user", "Allow", method_arn)
    return _policy("user", "Deny", method_arn)
