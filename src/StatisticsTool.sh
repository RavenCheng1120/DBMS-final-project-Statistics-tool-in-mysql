#!/bin/bash
Password=${1:-abc}
DB=${2:-statisticsdb}
User=${3:-root}
Host=${4:-localhost}

echo "Preparing connection..."
python3 StatisticsTable.py "$Host" "$DB" "$User" "$Password"