# lru_eviction_queue
A LRU Eviction Queue for the D programming language

# Documentation

[https://workhorsy.github.io/lru_eviction_queue/1.0.0/](https://workhorsy.github.io/lru_eviction_queue/1.0.0/)

# Generate documentation

```
dmd -c -D source/lru_eviction_queue.d -Df=docs/1.0.0/index.html
```

# Run unit tests

```
dub test --main-file=test/main.d
```

# TODO

* Add operator in
* Should evict event fire on clear and remove?
* Should we have an option to reorder the queue on get?
* Make it so the key is a template instead of a string.
