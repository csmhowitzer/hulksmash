# HULKSMASH v1.0 - NeoVim configuraiton

This is a NeoVim v0.10 configuration based on the LazyVim setup. A initially C# focused configuration relying heavily on Omnisharp and its supporting plugins.

## Installation

Make a backup of your local NeoVim files (if you want to preserve them)

```shell
mv ~/.config/nvim{,.bak}
mv ~/.local/share/nvim{,.bak}
mv ~/.local/state/nvim{,.bak}
mv ~/.cache/nvim{,.bak}
```

Clone the repo to get started

```shell
git clone https://github.com/csmhowitzer/hulksmash.git ~/.config/nvim/
```

Remove the `.git` folder so you can just add it to your own repository later

```shell
rm -rf ~/.config/nvim/.git
```

Start NeoVim!

```shell
nvim
```

## Current Depenencies

1. [Plugins](ihttps://github.com/csmhowitzer/plugins.git)
    - A plugin to nicely present markdown files in a presentation/slide format.
2. [Augment](https://www.augmentcode.co)
    - A free and paid for AI coding tool
    - This will require an initial setup ``
