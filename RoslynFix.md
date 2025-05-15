I figured it out and it might explain why it works for some and not others.

For some reason the initial auto targeting of the solution seems to break going to definitions. Roslyn target ing after the initial load will fix it but only in buffers opened after resetting the target. Setting the target will not fix already open buffers

My guess some people always set the target without relying on the auto targeting.

lock_target does not seem to affect the workaround

Issue:

1. open file in solution letting the plugin auto target
2. goto def
3. goto def inside of the decompiled file
4. Fails

Workaround:

1. open file in solution
2. `:Roslyn target` and select your solution
3. Close any existing decompiled buffers
4. goto def
5. goto def inside of the decompiled file
6. Works as expected
Ok please read @readthis.md this is a post someone had on the roslyn.nvim github issues thread. Can we make this workaround automated?
