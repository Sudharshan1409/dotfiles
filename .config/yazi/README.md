# Yazi Configuration Setup

This repository contains my Yazi configuration. Follow the steps below to clone the repository and set up your Yazi environment.

## Prerequisites

Ensure you have the following software installed on your system:

- Yazi

## Installation

1. **Clone the Repository**

   Open your terminal and run the following command to clone the repository into your Yazi configuration directory:

   For HTTPS

   ```sh
   git clone https://github.com/Sudharshan1409/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   stow yazi
   ```

   For SSH

   ```sh
   git clone git@github.com:Sudharshan1409/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   stow yazi
   ```

2. **Install Yazi Theme**

   Open Terminal and run the following command to install Yazi Theme:

   ```sh
   ya pack -a yazi-rs/flavors:catppuccin-frappe
   ```

3. **Customization**

   You can customize the configuration as you like. Change the appearance, or add new key bindings to suit your workflow.
