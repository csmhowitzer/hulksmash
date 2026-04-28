;; extends

;; `var` keyword → same color as predefined types (int, string, bool)
;; AST node: (implicit_type) confirmed via :InspectTree
(implicit_type) @type.builtin

;; Generic type arguments — class types → Yellow #f9e2af italic
;; AST node: (identifier) inside (type_argument_list) confirmed via :InspectTree
(type_argument_list (identifier) @type.parameter)

;; Generic type arguments — primitive types → muted blue #6b86ef italic
;; AST node: (predefined_type) inside (type_argument_list)
;; Separate capture name so italic doesn't bleed to ALL predefined types globally
(type_argument_list (predefined_type) @type.builtin.generic)

;; Attributes → Peach at priority 200, beats LSP @lsp.type.class.cs at 125
;; Fixes: [HttpGet] etc being colored as classes when @lsp.type.class.cs is active
(attribute name: (identifier) @attribute.c_sharp
  (#set! priority 200))

;; Parameter modifiers (out, ref, in, params) → Mauve like other keywords
;; AST node: (modifier) inside (parameter) confirmed via :InspectTree
;; This is distinct from access modifiers (public, private) which live in declarations
(parameter (modifier) @keyword)

