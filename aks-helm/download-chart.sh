#!/bin/bash

# Clone AWX operator repository
git clone https://github.com/ansible-community/awx-operator-helm.git temp-awx-operator

# Find and copy Helm chart
find temp-awx-operator -name "Chart.yaml" -type f
cp -r temp-awx-operator/charts/awx-operator awx-operator-chart 2>/dev/null || \
cp -r temp-awx-operator/helm awx-operator-chart 2>/dev/null || \
cp -r temp-awx-operator/chart awx-operator-chart 2>/dev/null || \
echo "Chart not found in expected locations"

# Cleanup
rm -rf temp-awx-operator

echo "Chart downloaded to awx-operator-chart/"