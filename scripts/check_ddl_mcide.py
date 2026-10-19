"""Check that the AERIE DDL and the mCIDE CSVs agree.

For every DDL column whose permissible values link to an mCIDE CSV, the bracketed
list in the DDL must equal the categories in that CSV. For assay_category and
assay_group, the expected list is restricted to platforms whose aerie_table is the
DDL table or "either". Exits non-zero on any mismatch.

Usage: uv run scripts/check_ddl_mcide.py [path/to/ddl.sql]
"""

import csv
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_DDL_PATH = REPO_ROOT / "ddl" / "0.1" / "AERIE0.1_MYSQL_ddl.sql"
MCIDE_LINK_PATTERN = re.compile(r"^\[(?P<values>[^\]]*)\]\(https://github\.com/[^/]+/[^/]+/blob/[^/]+/(?P<path>mCIDE/[^)]+)\)$")
TABLE_PATTERN = re.compile(r"CREATE TABLE (\w+) \((.*?)\n\);", re.DOTALL)
COLUMN_PATTERN = re.compile(r"^\s*(\w+) \w+ COMMENT '(.*)',?$", re.MULTILINE)


def read_mcide_rows(csv_path):
    with open(REPO_ROOT / csv_path, newline="") as csv_file:
        return list(csv.DictReader(csv_file))


def expected_categories(table_name, column_name, csv_path):
    mcide_rows = read_mcide_rows(csv_path)
    if column_name == "assay_category":
        return [row["assay_category"] for row in mcide_rows if row["aerie_table"] in (table_name, "either")]
    if column_name == "assay_group":
        assay_rows = read_mcide_rows("mCIDE/common/aerie_assay_categories.csv")
        groups_in_table = {row["assay_group"] for row in assay_rows if row["aerie_table"] in (table_name, "either")}
        return [row["assay_group"] for row in mcide_rows if row["assay_group"] in groups_in_table]
    return [row[column_name] for row in mcide_rows]


def check_ddl(ddl_path):
    problems = []
    linked_column_count = 0
    ddl_text = Path(ddl_path).read_text()
    for table_name, table_body in TABLE_PATTERN.findall(ddl_text):
        for column_name, comment_text in COLUMN_PATTERN.findall(table_body):
            try:
                comment = json.loads(comment_text)
            except json.JSONDecodeError as error:
                problems.append(f"{table_name}.{column_name}: comment is not valid JSON ({error})")
                continue
            link_match = MCIDE_LINK_PATTERN.match(comment["permissible"])
            if not link_match:
                continue
            linked_column_count += 1
            ddl_values =[value.strip() for value in link_match["values"].split(",")]
            mcide_values = expected_categories(table_name, column_name, link_match["path"])
            if ddl_values != mcide_values:
                problems.append(
                    f"{table_name}.{column_name}: DDL lists {ddl_values} but {link_match['path']} gives {mcide_values}"
                )
    if linked_column_count == 0:
        problems.append("no columns link to an mCIDE CSV; the link pattern may no longer match the DDL")
    return problems


if __name__ == "__main__":
    ddl_path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_DDL_PATH
    problems = check_ddl(ddl_path)
    for problem in problems:
        print(problem)
    print(f"{len(problems)} mismatch(es) in {ddl_path}")
    sys.exit(1 if problems else 0)
