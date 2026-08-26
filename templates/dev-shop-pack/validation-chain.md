# Engineering Validation Chain

Validation is independent and sequential. A producer never approves its own work.

1. **QA gate:** verify acceptance criteria, functional behavior, failure paths,
   references, and test evidence.
2. **Domain gate:** the relevant engineering reviewer checks contracts and
   domain-specific correctness. Multiple affected domains review in parallel.
3. **Architecture gate:** the tech lead checks boundary coherence, security
   posture, rollback, and release readiness.
4. **Stakeholder gate:** required only for actions the repository classifies as
   privileged, irreversible, destructive, or production-impacting.

A blocking finding returns to the producer with severity, file/location,
reason, and a concrete recommended action. After three unsuccessful review
cycles, stop retrying and escalate the approach for redesign.

Roles may read any relevant file, but they commit only within their write
domain. An out-of-domain defect becomes a tracked finding for the owning role.
