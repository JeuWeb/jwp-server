locals_without_parens = [
  # Query
  const: 2
]

[
  import_deps: [:phoenix],
  # inputs: ["*.{ex,exs}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{ex,exs}"],
  inputs: ["{mix,.formatter}.exs"],
  subdirectories: ["priv/*/migrations"]
]
