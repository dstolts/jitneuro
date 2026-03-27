# Session Awareness (Sprawl Prevention)

Not a WIP limit -- an awareness mechanism. At the start of every response where sessions are created or switched, display the active session count:

```
Active sessions: 5 | [session-name-1, session-name-2, ...]
```

If active sessions exceed 8, add a warning:
```
WARNING: 12 active sessions -- sprawl risk. Consider archiving completed work.
```

This keeps Owner informed so they can choose to consolidate or archive. No enforcement -- just visibility.
