# Git Configuration Setup

Follow the steps below to set up your Git configuration:

## Step 1: Clone the Repository

Clone the repository to the `~/.config/git` folder using the following command:

### For HTTPS
```bash
git clone https://github.com/Sudharshan1409/git-config.git ~/.config/git
```

### For SSH
```bash
git clone git@github.com:Sudharshan1409/git-config.git ~/.config/git
```

## Step 2: Update the Main `~/.gitconfig` File
```plaintext
[include]
    path = ~/.config/git/.gitconfig
```

## Yor're All Set!
