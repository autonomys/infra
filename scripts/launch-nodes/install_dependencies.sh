#!/bin/bash

# Function to check if Python is installed
check_python() {
  if ! command -v python3 &> /dev/null
  then
      echo "Python3 could not be found. Please install Python 3.x before proceeding."
      exit 1
  fi
}

# Function to create a virtual environment and install dependencies
install_dependencies() {
  # Check if virtualenv is installed, if not install it
  if ! python3 -m venv --help &> /dev/null; then
    echo "virtualenv not found, installing..."
    pip3 install virtualenv
  fi

  # Create virtual environment
  echo "Creating a virtual environment..."
  python3 -m venv subspace_env

  # Activate the virtual environment
  source subspace_env/bin/activate

  # Install required Python packages
  echo "Installing required dependencies with pip..."
  pip install paramiko tomli colorlog

  # Deactivate virtual environment after installing
  deactivate

  echo "Dependencies installed in 'subspace_env' virtual environment."
  echo "To activate it, run: source subspace_env/bin/activate"
}

# Check for Python installation
check_python

# Install dependencies
install_dependencies
