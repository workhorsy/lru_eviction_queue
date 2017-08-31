# lru_eviction_queue
A LRU Eviction Queue for the D programming language

# Documentation

[https://workhorsy.github.io/lru_eviction_queue/$VERSION/](https://workhorsy.github.io/lru_eviction_queue/$VERSION/)

# Generate documentation

```
dmd -c -D source/lru_eviction_queue.d -Df=docs/$VERSION/index.html
```

# Run unit tests

```
dub test --main-file=test/main.d
```

