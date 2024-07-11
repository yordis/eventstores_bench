# EventstoresBench

A benchmark comparing multiple Production-Ready Event Stores.

- https://hex.pm/packages/eventstore
- https://hex.pm/packages/spear

## How-To

### Run the benchmark

```bash
mix run -e "AppendBench.run()"
mix run -e "ReadBench.run()"
mix run -e "SubscribeBench.run()"
```
