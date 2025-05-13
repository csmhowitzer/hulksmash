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

## C# LSP

Originally this repo was configured to work with OmniSharp's LSP. However this
is no longer the case as [OmniSharp](https://github.com/OmniSharp/) was not
regularly maintained any longer. It did start off as a Microsoft maintained
repository for a C# LSP.

### Change to Roslyn

Roslyn started off as Microsoft's open-sourcing the C# compiler.
[OmniSharp-Roslyn](https://github.com/omnisharp/omnisharp-roslyn) is a
Roslyn-based LSP which Mason will install out of the box with `:MasonInstall
omnisharp`. However, even as an officially recognized repo for the open source
C# LSP. It isn't maintained well and no longer supported with a dedicated team.

### Maintainers to the rescue

So the rest of the backstory is that the new format is to use the
[roslyn.nvim](https://github.com/seblyng/roslyn.nvim) Roslyn-LSP. Mason will not
recognize this repo s the **OFFICIAL** repo for a C# LSP and thus you'll need to
configure this differently. This configuration will add the roslyn lsp via
**Mason**, but we need to add a custom mason registry.

**Steps:**

1. Create a *mason_registry.lua* plugin in */lua/plugins/* directory.

```lua
return {
  require("mason").setup({
    registries = {
      "github:mason-org/mason-registry",
      "github:Crashdummyy/mason-registry",
    },
  }),
}
```

2. Install *Roslyn LSP* via `:MasonInstall roslyn`
    - **Note** `:Mason` command will not work properly until step 3
3. After installing via **Mason** comment out or remove the *mason_registry.lua*
   plugin.
4. Now you need to actually add in the *roslyn.nvim* plugin!
    - refer to [roslyn.nivm](https://github.com/seblyng/roslyn.nvim)

#### Troubleshooting

1. The only issues really stem from **OmniSharp** still installing and running
   on *LSPAttach*
    - **OmniSharp** was a `:LazyExtras` install, and a *csharp.nvim*
    installation. Ensure those are not blockers.
