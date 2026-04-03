# Color Palette & Semantic Highlighting Reference

## Color Scale: Fade to Stand Out

```
← FADE                                    STAND OUT →
Cyan → Deep Blue → Blue → Purple → Red → Orange → Yellow → Green
```

Cool colors fade into the background. Warm colors demand attention.

---

## Tier System

| Tier | Elements | Color Direction | Notes |
|------|----------|-----------------|-------|
| **Tier 1** | Class, Struct, Namespace | Warm — Yellow | Most prominent, type definitions |
| **Tier 1** | Type Parameters `<T>` | Warm — Yellow *(italic)* | Same hue as Tier 1; italic signals "abstract placeholder" |
| **Tier 1b** | Interface, Enum, Attribute/Decorator | Warm adjacent — Cyan/Teal | Type-level but secondary; `@attribute` overrides LSP class assignment |
| **Electric** | Constants | Electric Yellow | Standalone — must stand out from all tiers |
| **Tier 2** | Methods, Properties, Fields, Extension Methods | Mid-warm — Orange/Blue | Members |
| **Tier 3** | Static Members, Enum Members | Mid — Red/Cyan | Special members |
| **Tier 4** | Parameters *(italic)*, Local Variables, Lambdas | Cool — Grey/Blue | Italic vs no-italic is the differentiator; lambdas collapse to locals via LSP |
| **Tier 5** | Keywords, Operators, Punctuation | Deep cool — Blue/Overlay | Should fade; syntax not semantics |
| **Tier 5b** | Predefined types (`int`, `string`, `bool`, `void`) | Same as keywords — Mauve | Visually indistinguishable from keywords; language-provided, not user-defined |

---

## Color Library

### Catppuccin Mocha

| Name       | Hex       | Notes               |
|------------|-----------|---------------------|
| Rosewater  | `#f5e0dc` |                     |
| Flamingo   | `#f2cdcd` |                     |
| Pink       | `#f5c2e7` |                     |
| Mauve      | `#cba6f7` | Purple              |
| Red        | `#f38ba8` |                     |
| Maroon     | `#eba0ac` |                     |
| Peach      | `#fab387` | Orange              |
| Yellow     | `#f9e2af` |                     |
| Green      | `#a6e3a1` |                     |
| Teal       | `#94e2d5` |                     |
| Sky        | `#89dceb` |                     |
| Sapphire   | `#74c7ec` | Cyan                |
| Blue       | `#89b4fa` |                     |
| Lavender   | `#b4befe` |                     |
| Text       | `#cdd6f4` | Default text        |
| Subtext 1  | `#bac2de` |                     |
| Subtext 0  | `#a6adc8` |                     |
| Overlay 2  | `#9399b2` |                     |
| Overlay 1  | `#7f849c` |                     |
| Overlay 0  | `#6c7086` | Near-fade           |
| Surface 2  | `#585b70` |                     |
| Surface 1  | `#45475a` |                     |
| Surface 0  | `#313244` |                     |
| Base       | `#1e1e2e` | Background          |
| Mantle     | `#181825` |                     |
| Crust      | `#11111b` |                     |

### Catppuccin Latte (Light Theme)

| Name       | Hex       | Notes               |
|------------|-----------|---------------------|
| Rosewater  | `#dc8a78` |                     |
| Flamingo   | `#dd7878` |                     |
| Pink       | `#ea76cb` |                     |
| Mauve      | `#8839ef` | Purple              |
| Red        | `#d20f39` |                     |
| Maroon     | `#e64553` |                     |
| Peach      | `#fe640b` | Orange              |
| Yellow     | `#df8e1d` |                     |
| Green      | `#40a02b` |                     |
| Teal       | `#179299` |                     |
| Sky        | `#04a5e5` |                     |
| Sapphire   | `#209fb5` | Cyan                |
| Blue       | `#1e66f5` |                     |
| Lavender   | `#7287fd` |                     |
| Text       | `#4c4f69` | Default text        |
| Subtext 1  | `#5c5f77` |                     |
| Subtext 0  | `#6c6f85` |                     |
| Overlay 2  | `#7c7f93` |                     |
| Overlay 1  | `#8c8fa1` |                     |
| Overlay 0  | `#9ca0b0` | Near-fade           |
| Surface 2  | `#acb0be` |                     |
| Surface 1  | `#bcc0cc` |                     |
| Surface 0  | `#ccd0da` |                     |
| Base       | `#eff1f5` | Background          |
| Mantle     | `#e6e9ef` |                     |
| Crust      | `#dce0e8` |                     |

### Catppuccin Frappé

| Name       | Hex       | Notes               |
|------------|-----------|---------------------|
| Rosewater  | `#f2d5cf` |                     |
| Flamingo   | `#eebebe` |                     |
| Pink       | `#f4b8e4` |                     |
| Mauve      | `#ca9ee6` | Purple              |
| Red        | `#e78284` |                     |
| Maroon     | `#ea999c` |                     |
| Peach      | `#ef9f76` | Orange              |
| Yellow     | `#e5c890` |                     |
| Green      | `#a6d189` |                     |
| Teal       | `#81c8be` |                     |
| Sky        | `#99d1db` |                     |
| Sapphire   | `#85c1dc` | Cyan                |
| Blue       | `#8caaee` |                     |
| Lavender   | `#babbf1` |                     |
| Text       | `#c6d0f5` | Default text        |
| Subtext 1  | `#b5bfe2` |                     |
| Subtext 0  | `#a5adce` |                     |
| Overlay 2  | `#949cbb` |                     |
| Overlay 1  | `#838ba7` |                     |
| Overlay 0  | `#737994` | Near-fade           |
| Surface 2  | `#626880` |                     |
| Surface 1  | `#51576d` |                     |
| Surface 0  | `#414559` |                     |
| Base       | `#303446` | Background          |
| Mantle     | `#292c3c` |                     |
| Crust      | `#232634` |                     |

### Catppuccin Macchiato

| Name       | Hex       | Notes               |
|------------|-----------|---------------------|
| Rosewater  | `#f4dbd6` |                     |
| Flamingo   | `#f0c6c6` |                     |
| Pink       | `#f5bde6` |                     |
| Mauve      | `#c6a0f6` | Purple              |
| Red        | `#ed8796` |                     |
| Maroon     | `#ee99a0` |                     |
| Peach      | `#f5a97f` | Orange              |
| Yellow     | `#eed49f` |                     |
| Green      | `#a6da95` |                     |
| Teal       | `#8bd5ca` |                     |
| Sky        | `#91d7e3` |                     |
| Sapphire   | `#7dc4e4` | Cyan                |
| Blue       | `#8aadf4` |                     |
| Lavender   | `#b7bdf8` |                     |
| Text       | `#cad3f5` | Default text        |
| Subtext 1  | `#b8c0e0` |                     |
| Subtext 0  | `#a5adcb` |                     |
| Overlay 2  | `#939ab7` |                     |
| Overlay 1  | `#8087a2` |                     |
| Overlay 0  | `#6e738d` | Near-fade           |
| Surface 2  | `#5b6078` |                     |
| Surface 1  | `#494d64` |                     |
| Surface 0  | `#363a4f` |                     |
| Base       | `#24273a` | Background          |
| Mantle     | `#1e2030` |                     |
| Crust      | `#181926` |                     |

### OneDark Pro (Reference)

| Name    | Hex       | Used For                           |
|---------|-----------|------------------------------------|
| Yellow  | `#e5c07b` | Types — class, struct, namespace   |
| Red     | `#e06c75` | Variables, fields, properties      |
| Blue    | `#61afef` | Functions, methods                 |
| Orange  | `#d19a66` | Constants, numbers                 |
| Cyan    | `#56b6c2` | Interfaces, enum members, builtins |
| Purple  | `#c678dd` | Keywords                           |
| Grey    | `#abb2bf` | Parameters, operators              |
| Green   | `#98c379` | Strings                            |

### Electric Colors (Plugin UI)

Reserved for UI chrome and highest-priority signals. Avoid for common syntax.

| Name            | Hex       | Plugin / Usage                              |
|-----------------|-----------|---------------------------------------------|
| Electric Yellow | `#F7DC6F` | scratch-manager border                      |
| Electric Green  | `#a6d189` | scratch-manager dashboard; m_augment title  |
| Sapphire        | `#74c7ec` | scratch-manager title; m_augment footer     |
| Blue            | `#89b4fa` | scratch-manager select border               |
| Mauve           | `#cba6f7` | m_augment chat border                       |

---

## Proposed Tier → Color Mapping (Draft)

> Work in progress — tweak after live testing with `:Inspect`

| Tier     | Element                  | Hex              | Source              | Notes                        |
|----------|--------------------------|------------------|---------------------|------------------------------|
| Tier 1   | Class, Struct            | `#f9e2af`        | Catppuccin Yellow      | Warm, most prominent         |
| Tier 1c  | Namespace                | `#cba6f7`        | Mauve      | Warm, most prominent         |
| Tier 1   | Type Parameters <T>      | `#f9e2af` italic | Catppuccin Yellow      | Italic = abstract placeholder; `@lsp.type.typeParameter` |
| Tier 1b  | Interface                | `#f2cdcd`        | Catppuccin Flamingo        | Complementary to yellow      |
| Tier 1b  | Enum                     | `#85c1dc`        | Catppuccin Cyan (Frappe)     | Adjacent to cyan             |
| Tier 1b  | Attribute/Decorator      | `#d19a66`        | OneDark Orange     | `@attribute` overrides `@lsp.type.class` |
| Electric | Constants                | `#8839ef` bold   | Catppuccin Mauve (Latte)     | Must stand out above all     |
| Tier 2   | Methods, Extension Meth. | `#d19a66`        | OneDark Orange        |                              |
| Tier 2   | Properties, Fields       | `#e5c07b`        | OneDark Yellow    | Mid-warm                     |
| Tier 3   | Static Members           | `#fab387`        | Catppuccin Peach      | Shares Tier 1 hue            |
| Tier 3   | Enum Members             | `#fab387`        | Catppuccin Peach        | Shares Interface hue         |
| Tier 4   | Parameters               | `#f38ba8` italic | Catppuccin Red        | Italic is the differentiator |
| Tier 4   | Local Variables, Lambdas | `#b4befe`        | Catppuccin Lavender        | Lambdas collapse here via LSP |
| Tier 5   | Keywords                 | `#8839ef`        | Catppuccin Mauve (Latte)     | Fade — let semantics dominate|
| Tier 5   | Operators, Punctuation   | `#89dceb`        | Catppuccin Sky | This really should be the current color, I like it               |
| Tier 5b  | Predefined types         | `#cba6f7`        | Catppuccin Mauve    | `@type.builtin`; same family as keywords, visually a keyword |
| —        | Strings                  | `#a6e3a1`        | Catppuccin Green    |                              |
| —        | Numbers                  | `#fab387`        | Catppuccin Peach    |                              |
| —        | Comments                 | `#FF0000`        | Custom              | Your intentional red         |

---

## Live Inspection Log

> Built from real `:Inspect` output. These are the confirmed default colors and whether we like them.
> Winner = highest priority group that actually applies the color.

| Construct | Example | Winner Group | Resolved Color | Verdict |
|-----------|---------|--------------|----------------|---------|
| `using` keyword | `using System;` | `@lsp.type.keyword.cs` → `Keyword` | `#cba6f7` Mauve | ✅ Like |
| Namespace | `System.Text.Json` | `@lsp.type.namespace.cs` → `@module` | `#b4befe` Lavender | ✅ Like |
| String | `"hello"`, `$"..."`, `@"..."` | `@lsp.type.string.cs` → `String` | `#a6e3a1` Green | ✅ Like |
| Escape chars | `\r\n` | `@string.escape.c_sharp` → `@string.escape` | `#f5c2e7` Pink | ✅ Like |
| Class | `MyClass` | `@lsp.type.class.cs` → `Type` | `#f9e2af` Yellow | ✅ Like |
| Parameter | `Method(string param)` | `@lsp.type.parameter.cs` → `@parameter` | `#eba0ac` Maroon + italic | ✅ Confirmed — LSP carries color+italic at usage sites; signature uses `@variable.parameter.c_sharp` |
| Method | `MyMethod()` | `@lsp.type.method.cs` → `Function` | `#89b4fa` Blue | ✅ Like |
| Attribute | `[Connection(...)]` | `@lsp.type.class.cs = {}` → falls through to `@attribute.c_sharp` → `Constant` | `#fab387` Peach | ✅ Like — fixed by disabling LSP class token, Treesitter distinguishes correctly |
| Class | `GetImageQueue` | `@lsp.type.class.cs = {}` → falls through to `@type.c_sharp` → `Type` | `#f9e2af` Yellow | ✅ Like — Treesitter fallback holds |
| Class as type | `UtilityService` (param) | `@lsp.type.class.cs = {}` → falls through to `@type.c_sharp` → `Type` | `#f9e2af` Yellow | ✅ Like — same as class, correct |
| Interface | `IQueuedWorkflow` | `@lsp.type.interface.cs` → `@lsp.type.interface` | `#f2cdcd` Flamingo | ✅ Like |
| Constant | `MY_CONST` | `@lsp.type.constant.cs` (priority 125) | `#f5c2e7` Pink bold | ✅ Like — bold makes it pop, distinct from attributes/interfaces |

---

## Notes & Decisions

- **Constants = Electric Yellow** (`#F7DC6F`) — same as plugin borders, unmistakable
- **Parameters vs Locals** — same grey color, italic is the only differentiator
- **Lambdas** — collapse to Tier 4 locals; LSP surfaces lambda internals as variables/parameters, no separate target exists
- **Type Parameters** — Tier 1 Yellow + italic; `@lsp.type.typeParameter` is the target group
- **Attributes/Decorators** — Tier 1b Teal; use `@attribute` (Treesitter) to override `@lsp.type.class` so they don't blend with user-defined classes
- **Predefined types** — Tier 5b Mauve (`#cba6f7`); `@type.builtin` is the Treesitter target; same color as keywords — `int` and `if` live in the same visual family
- **Interface/Enum/Attribute family** — cyan/teal, complementary (not contrasting) to Class/Struct yellow
- **Keywords fade** — blue pushes them back so named things dominate
- **Strings are green** — distinct from types; separates data from structure visually
- **Properties** — `#c9a0c9` muted orchid; sits between warm and cool, bridges structure and data; hook: `@lsp.type.property.cs` priority 125; more saturation felt too much, value is right
- **Warm/Cool semantic rule** — Cool = structure/flow (keywords, namespaces, methods, static refs); Warm = data/values (constants, parameters, operators, string internals). Use this to guide future color decisions. Interfaces (Flamingo) are a known intentional exception — light enough it doesn't break the feel.
- **Operators** — `#c4726a` brick red (orange-shifted warm); muted/pastel, stands out against cool surroundings without reading as "error"; hook: `@lsp.type.operator.cs` priority 125
- **Extension Methods** — `#74c7ec` Sapphire; between teal and blue, distinct from regular methods (`#89b4fa`); shared with static classes; hook: `@lsp.type.extensionMethod.cs` priority 125
- **Static Classes** — `#d4a574` warm amber; warm/data side, distinct from regular class Yellow `#f9e2af`; hook: `@lsp.typemod.class.static.cs` priority 125
- **Static Fields** — `#e8b860` yellow-orange bold; warm/data side, distinct from static class amber; hook: `@lsp.typemod.field.static.cs` priority 127
- **Predefined types / primitives (`int`, `string`, `bool`)** — `#6b86ef` cool blue-mauve; decoupled from keywords by clearing `@lsp.type.keyword.cs = {}`; hook: `@type.builtin.c_sharp` priority 100 (Treesitter wins once LSP cleared); Treesitter node: `predefined_type`

## ⏳ Custom Treesitter Query TODOs
> File to create: `~/.config/nvim/queries/c_sharp/highlights.scm`
> Must start with `;; extends` to avoid replacing the built-in grammar

### 1. `var` keyword → primitive type color
- **Goal:** `var` should use the same cool blue-mauve `#6b86ef` as `int`/`string`/`bool`
- **Problem:** `var` falls to `@keyword.c_sharp` → Mauve (same as `if`/`else`/`for`)
- **AST node confirmed:** `(implicit_type)` — seen throughout tree_example.md (lines 248, 259, 299, 345, 374, 407, 444, 483, etc.)
- **Query to write:**
  ```scheme
  ;; extends
  (implicit_type) @type.builtin
  ```
- **Why it works:** Maps `var` to `@type.builtin` which we've already styled to `#6b86ef`; Treesitter at priority 100 will win since `@lsp.type.keyword.cs` is cleared

### 2. Generic type arguments `List<MyType>` → italic type parameter
- **Goal:** Type parameters (the `T` in `List<T>`, `MyType` in `List<MyType>`) should be visually distinct — italics suggested
- **Problem:** No LSP or default Treesitter capture targets the argument position specifically
- **AST node confirmed:** `(identifier)` directly inside `(type_argument_list)` — seen at lines 233-234, 307-308, 354-355, etc. in tree_example.md
- **Query to write:**
  ```scheme
  (type_argument_list (identifier) @type.parameter)
  ```
  Then add `["@type.parameter"] = { italic = true }` to catppuccin.lua custom_highlights
- **Note:** Decide on a color — could inherit from class Yellow `#f9e2af` with italic, or use a distinct cooler tone since type params are structural placeholders

