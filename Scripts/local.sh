#!/bin/bash

# make sure the script is run from the Scripts folder
if [ "$(dirname "$0")" != "." ]; then
    echo "Please run the script from the Scripts folder"
    exit 1
fi

# Check if the Localizable.xcstrings file exists
if [ ! -f "../FinancialFlow/FinancialFlow/Localizable.xcstrings" ]; then
    echo "Error: Localizable.xcstrings file not found"
    exit 1
fi

# create the Generated directory if it doesn't exist
mkdir -p ../FinancialFlowApp/Sources/Generated

# convert the xcstrings to strings using the swift script directly
swift xcstrings-to-strings.swift ../FinancialFlow/FinancialFlow/Localizable.xcstrings ../FinancialFlowApp/Sources/Generated/Localizable.strings

# cd to the FinancialFlowApp folder
cd ../FinancialFlowApp

# generate the code for the resources with the plugin
swift package --allow-writing-to-package-directory generate-code-for-resources 

# remove the generated Localizable.strings
 rm Sources/Generated/Localizable.strings

# Return to original directory
cd ../Scripts

echo "Resource generation completed successfully!"
