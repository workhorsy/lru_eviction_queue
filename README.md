# LRU Eviction Queue
A LRU Eviction Queue for the D programming language

# Documentation

[https://workhorsy.github.io/lru_eviction_queue/1.2.0/](https://workhorsy.github.io/lru_eviction_queue/1.2.0/)

# Generate documentation

```
dmd -c -D source/lru_eviction_queue.d -Df=docs/1.2.0/index.html
```

# Run unit tests

```
dub test --main-file=test/main.d
```

[![Dub version](https://img.shields.io/dub/v/lru_eviction_queue.svg)](https://code.dlang.org/packages/lru_eviction_queue)
[![Dub downloads](https://img.shields.io/dub/dt/lru_eviction_queue.svg)](https://code.dlang.org/packages/lru_eviction_queue)
[![License](https://img.shields.io/badge/license-BSL_1.0-blue.svg)](https://raw.githubusercontent.com/workhorsy/lru_eviction_queue/master/LICENSE)

# TODO

* Add operator in
* Should evict event fire on clear and remove?
* Should we have an option to reorder the queue on get?
