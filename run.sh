#!/bin/bash

# Initialize variables
script="test_update"
autoRunLoc=$(readlink -f "$0")
proc_name="test_print_script" 
args=()
version_location="./some_package/__init__.py"
version="__version__"
repository="Mak-Wei-Zheng/toy_repo"
repository_path="https://github.com/$repository"

old_args=$@

echo "$old_args"

# Check if pm2 is installed
# if ! command -v pm2 &> /dev/null
# then
#     echo "pm2 could not be found. To install see: https://pm2.keymetrics.io/docs/usage/quick-start/"
#     exit 1
# fi

# Locate the path of the pm2 executable
pm2_path=$(which pm2)

# Check if pm2 is found
if [ -z "$pm2_path" ]; then
  echo "pm2 could not be found. To install see: https://pm2.keymetrics.io/docs/usage/quick-start/"
  exit 1
fi

# Extract the directory containing pm2
pm2_dir=$(dirname "$pm2_path")

# Export the directory to the PATH environment variable
export PATH="$pm2_dir:$PATH"

# Optionally, print the updated PATH
echo "pm2 directory added to PATH: $pm2_dir"
echo "Updated PATH: $PATH"

# Define your function for version comparison and other utilities here

# Checks if $1 is smaller than $2
version_less_than_or_equal() {
    [  "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
}

# Checks if $1 is smaller than $2
version_less_than() {
    [ "$1" = "$2" ] && return 1 || version_less_than_or_equal $1 $2
}

# compares the local version vs the current version on the repository
get_version_difference() {
    local tag1="$1"
    local tag2="$2"

    # Extract the version numbers from the tags
    local version1=$(echo "$tag1" | sed 's/v//')
    local version2=$(echo "$tag2" | sed 's/v//')

    # Split the version numbers into an array
    IFS='.' read -ra version1_arr <<< "$version1"
    IFS='.' read -ra version2_arr <<< "$version2"

    # Calculate the numerical difference
    local diff=0
    for i in "${!version1_arr[@]}"; do
        local num1=${version1_arr[$i]}
        local num2=${version2_arr[$i]}

        # Compare the numbers and update the difference
        if (( num1 > num2 )); then
            diff=$((diff + num1 - num2))
        elif (( num1 < num2 )); then
            diff=$((diff + num2 - num1))
        fi
    done

    strip_quotes $diff
}

# Check for the operating system
check_package_installed() {
    local package_name="$1"
    os_name=$(uname -s)

    if [[ "$os_name" == "Linux" ]]; then
        # Use dpkg-query to check if the package is installed
        if dpkg-query -W -f='${Status}' "$package_name" 2>/dev/null | grep -q "installed"; then
            return 1
        else
            return 0
        fi
    elif [[ "$os_name" == "Darwin" ]]; then
         if brew list --formula | grep -q "^$package_name$"; then
            return 1
        else
            return 0
        fi
    else
        echo "Unknown operating system"
        return 0
    fi
}

check_variable_value_on_github() {
    local repo="$1"
    local file_path="$2"
    local variable_name="$3"
    local branch="$4"

    local url="https://api.github.com/repos/$repo/contents/$file_path?ref=$branch"
    local response=$(curl -s "$url")

    # Check if the response contains an error message
    if [[ $response =~ "message" ]]; then
        echo "Error: Failed to retrieve file contents from GitHub."
        return 1
    fi

    # Extract the base64 content and decode it
    json_content=$(echo "$response" | jq -r '.content' | base64 --decode)

    # Extract the "subnet_version" value using jq
    subnet_version=$(echo "$json_content" | jq -r '.subnet_version')

    # Print the value
    echo "$subnet_version"
}

strip_quotes() {
    local input="$1"

    # Remove leading and trailing quotes using parameter expansion
    local stripped="${input#\"}"
    stripped="${stripped%\"}"

    echo "$stripped"    
}

read_version_value() {
    jq -r $version "$version_location"
}

check_package_installed "jq"
if [ "$?" -ne 1 ]; then
    echo "Missing 'jq'. Please install it first."
    exit 1
fi

if [ ! -d "./.git" ]; then
    echo "This installation does not seem to be a Git repository. Please install from source."
    exit 1
fi

# Loop through all command line arguments
# Similar logic to handle script arguments; adjust as necessary
# Loop through all command line arguments
while [[ $# -gt 0 ]]; do
  arg="$1"

  # Check if the argument starts with a hyphen (flag)
  if [[ "$arg" == -* ]]; then
    # Check if the argument has a value
    if [[ $# -gt 1 && "$2" != -* ]]; then
          if [[ "$arg" == "--script" ]]; then
            script="$2";
            shift 2
        else
            # Add '=' sign between flag and value
            args+=("'$arg'");
            args+=("'$2'");
            shift 2
        fi
    else
      # Add '=True' for flags with no value
      args+=("'$arg'");
      shift
    fi
  else
    # Argument is not a flag, add it as it is
    args+=("'$arg '");
    shift
  fi
done

branch=$(git branch --show-current)
echo "Watching branch: $branch"
echo "PM2 process names: $proc_name, $generate_proc_name"

current_version=$(read_version_value)

# Function to check and restart pm2 processes
check_and_restart_pm2() {
    local proc_name=$1
    local script_path=$2
    local proc_args=("${!3}")

    if pm2 status | grep -q $proc_name; then
        echo "The script $script_path is already running with pm2 under the name $proc_name. Stopping and restarting..."
        pm2 delete $proc_name
    fi

    echo "Running $script_path with the following pm2 config:"

    joined_args=$(printf "'%s'," "${proc_args[@]}")
    joined_args=${joined_args%,}

    echo "module.exports = {
      apps : [{
        name   : '$proc_name',
        script : '$script_path',
        interpreter: 'python3',
        min_uptime: '5m',
        max_restarts: '5',
        args: [$joined_args]
      }]
    }" > $proc_name.app.config.js

    cat $proc_name.app.config.js
    pm2 start $proc_name.app.config.js
}

# Continuous checking and updating logic
while true; do
    # Get the current minute
    current_minute=$(date +'%M')

    # Check if the current minute is even
    if [ $((10#$current_minute % 2)) -ne 0 ]; then
        sleep 5 # Sleep for 5 seconds and check again
        continue
    fi

    # Proceed with checks only at the 30-minute mark
    latest_version=$(check_variable_value_on_github $respository $version_location $version $branch)

    while [ -z "$latest_version" ]; do
        echo "Waiting for latest version to be set..."
        sleep 1
    done

    echo "Latest version: $latest_version"
    latest_version="${latest_version#"${latest_version%%[![:space:]]*}"}"
    current_version="${current_version#"${current_version%%[![:space:]]*}"}"

    if [ -n "$latest_version" ] && ! echo "$latest_version" | grep -q "Error" && version_less_than $current_version $latest_version; then
        echo "Updating due to version mismatch. Current: $current_version, Latest: $latest_version"
        if git pull origin $branch; then
            echo "New version published. Updating the local copy."
            pip install -e .
            check_and_restart_pm2 "$proc_name" "$script" args[@]
            current_version=$(read_version_value)
            echo "Update completed. Continuing monitoring..."
        else
            echo "Please stash your changes using git stash."
        fi
    else
        echo "You are up-to-date with the latest version."
    fi
    sleep 300
done