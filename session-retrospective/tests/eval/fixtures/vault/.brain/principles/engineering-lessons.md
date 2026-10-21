# Engineering lessons

## Testing
- Behavioral tests: verify WHAT gets passed to save/send/publish, not the method's internal structure.
- Mocked data must tell a story coherent with the real flow.

## Verify-before-react
- Before asserting the state of a process (ran, failed, stopped), look at it on the live system (`ps`, the process log, `launchctl list`) instead of deducing it. Example: a launchd job believed dead was running.
- Before giving the time of day, run `date`: the date in the prompt is stale.

## Refactoring
- Before touching a signature, grep its callers.

## Environment
- Before `rm -rf` on a project directory, run `pwd` as a separate command first: if the directory is the session's working directory (or a parent), deleting it orphans the chat, which can no longer be resumed.
