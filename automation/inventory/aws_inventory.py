"""AWS inventory: normalized listing of EC2 and RDS instances via boto3.

Works against real AWS (using normal boto3 credential resolution -- env
vars, shared config, instance profile, etc.) or, in the test suite, against
moto's `@mock_aws` decorator. No real AWS calls are made during tests.

Pending (see docs/logs/python-automation.md): once Terraform has applied
real infrastructure, this module can be pointed at the real `dev`
environment simply by running it with valid AWS credentials -- no code
changes required.
"""
from __future__ import annotations

from datetime import datetime, timezone
from typing import Optional

import boto3

DEFAULT_REGION = "sa-east-1"


def _tags_to_dict(tags: Optional[list]) -> dict:
    if not tags:
        return {}
    return {tag["Key"]: tag["Value"] for tag in tags}


def list_ec2_instances(region: str = DEFAULT_REGION) -> list:
    """Return a normalized list of EC2 instances in `region`.

    Each item: {id, resource_type, instance_type, state, tags, name, region}.
    """
    client = boto3.client("ec2", region_name=region)
    paginator = client.get_paginator("describe_instances")

    instances = []
    for page in paginator.paginate():
        for reservation in page.get("Reservations", []):
            for instance in reservation.get("Instances", []):
                tags = _tags_to_dict(instance.get("Tags"))
                instances.append(
                    {
                        "id": instance["InstanceId"],
                        "resource_type": "ec2",
                        "instance_type": instance.get("InstanceType"),
                        "state": instance.get("State", {}).get("Name"),
                        "tags": tags,
                        "name": tags.get("Name"),
                        "region": region,
                    }
                )
    return instances


def list_rds_instances(region: str = DEFAULT_REGION) -> list:
    """Return a normalized list of RDS DB instances in `region`.

    Each item: {id, resource_type, instance_type, state, engine, tags,
    name, region}.
    """
    client = boto3.client("rds", region_name=region)
    paginator = client.get_paginator("describe_db_instances")

    instances = []
    for page in paginator.paginate():
        for db in page.get("DBInstances", []):
            tags = _tags_to_dict(db.get("TagList"))
            instances.append(
                {
                    "id": db["DBInstanceIdentifier"],
                    "resource_type": "rds",
                    "instance_type": db.get("DBInstanceClass"),
                    "state": db.get("DBInstanceStatus"),
                    "engine": db.get("Engine"),
                    "tags": tags,
                    "name": tags.get("Name", db["DBInstanceIdentifier"]),
                    "region": region,
                }
            )
    return instances


def get_inventory(region: str = DEFAULT_REGION) -> dict:
    """Return the full normalized inventory (EC2 + RDS) for `region`."""
    return {
        "region": region,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "ec2": list_ec2_instances(region=region),
        "rds": list_rds_instances(region=region),
    }
