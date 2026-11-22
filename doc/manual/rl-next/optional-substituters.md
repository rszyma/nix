---
synopsis: "Substituters can be marked `optional`"
issues: [6901, 15419]
---

A substituter can now be marked optional with the `optional` store setting, for example `http://192.168.1.2:5000?optional=true`.
Any error from an optional substituter, such as an unreachable host or a failed download, is treated as if it does not have the path.
Nix moves on to the next substituter, or builds the path if no substituter has it.
This suits caches on other machines that are often switched off.

Setting [`fallback`](@docroot@/command-ref/conf-file.md#conf-fallback) to `true` has the same effect as marking every substituter optional.
