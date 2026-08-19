"""Tests for automation.inventory.aws_inventory using moto -- NO real AWS
calls are made. `mock_aws` patches boto3 for the duration of each test."""
from __future__ import annotations

import boto3
from moto import mock_aws

from automation.inventory.aws_inventory import get_inventory, list_ec2_instances, list_rds_instances

REGION = "sa-east-1"


@mock_aws
def test_list_ec2_instances_empty_region():
    assert list_ec2_instances(region=REGION) == []


@mock_aws
def test_list_ec2_instances_returns_normalized_fields():
    ec2 = boto3.client("ec2", region_name=REGION)
    response = ec2.run_instances(ImageId="ami-12345678", MinCount=1, MaxCount=1, InstanceType="t3.micro")
    instance_id = response["Instances"][0]["InstanceId"]
    ec2.create_tags(Resources=[instance_id], Tags=[{"Key": "Name", "Value": "test-web-01"}])

    instances = list_ec2_instances(region=REGION)

    assert len(instances) == 1
    item = instances[0]
    assert item["id"] == instance_id
    assert item["resource_type"] == "ec2"
    assert item["instance_type"] == "t3.micro"
    assert item["region"] == REGION
    assert item["name"] == "test-web-01"
    assert item["tags"] == {"Name": "test-web-01"}
    assert item["state"] in ("pending", "running")


@mock_aws
def test_list_rds_instances_empty_region():
    assert list_rds_instances(region=REGION) == []


@mock_aws
def test_list_rds_instances_returns_normalized_fields():
    rds = boto3.client("rds", region_name=REGION)
    rds.create_db_instance(
        DBInstanceIdentifier="test-db-01",
        DBInstanceClass="db.t3.micro",
        Engine="mysql",
        MasterUsername="admin",
        MasterUserPassword="ChangeMe12345",
        AllocatedStorage=20,
        Tags=[{"Key": "Environment", "Value": "dev"}],
    )

    instances = list_rds_instances(region=REGION)

    assert len(instances) == 1
    item = instances[0]
    assert item["id"] == "test-db-01"
    assert item["resource_type"] == "rds"
    assert item["engine"] == "mysql"
    assert item["instance_type"] == "db.t3.micro"
    assert item["tags"] == {"Environment": "dev"}
    assert item["region"] == REGION


@mock_aws
def test_get_inventory_combines_ec2_and_rds():
    ec2 = boto3.client("ec2", region_name=REGION)
    ec2.run_instances(ImageId="ami-12345678", MinCount=1, MaxCount=1, InstanceType="t3.micro")

    rds = boto3.client("rds", region_name=REGION)
    rds.create_db_instance(
        DBInstanceIdentifier="test-db-02",
        DBInstanceClass="db.t3.micro",
        Engine="mysql",
        MasterUsername="admin",
        MasterUserPassword="ChangeMe12345",
        AllocatedStorage=20,
    )

    inventory = get_inventory(region=REGION)

    assert inventory["region"] == REGION
    assert "generated_at" in inventory
    assert len(inventory["ec2"]) == 1
    assert len(inventory["rds"]) == 1
