# Features
This library provides a zig implementation of the Adaptive Radix Tree or ART. The ART operates similar to a traditional radix tree but avoids the wasted space of internal nodes by changing the node size. It makes use of 4 node sizes (4, 16, 48, 256), and can guarantee that the overhead is no more than 52 bytes per key, though in practice it is much lower.
As a radix tree, it provides the following:

  -  O(k) operations. In many cases, this can be faster than a hash table since the hash function is an O(k) operation, and hash tables have very poor cache locality.
  -  Minimum / Maximum value lookups
  -  Prefix compression
  -  Ordered iteration
  -  Prefix based iteration

NOTE: this section copied from [armon/libart](https://github.com/armon/libart)

# Usage 
See [src/test_art.zig](src/test_art.zig)

### **Important Notes**
This library accepts zig string slices (`[]const u8`) and requires they are null terminated _AND_ their length must be incremented by 1 prior to being submitted to `insert()`, `delete()` and `search()`.  This is demonstrated thoroughly in [src/test_art.zig](src/test_art.zig).  As an example the key "A" would need to be converted to "A\x00". 

This is a consequence of porting from c to zig.  Zig's safe build modes (debug and release-safe) do runtime bounds checks on slices.  Art insert(), search(), and delete() methods assert their key parameters are null terminated and length incremented (`key[key.len-1] == 0`).  This ensures that the bounds checks pass.  

`iterPrefix()` on the other hand expects NON null terminated slices.  It searches the tree for keys which start with  its prefix parameter.  A null character at the end of a prefix would prevent matches.

### Build
```sh
# creates zig-cache/lib/liblibart.a
# debug
$ zig build 

# release
$ zig build -Drelease-safe # or release-fast or release-small
```

### Test
```sh
$ zig build test
```

### Run repl
```sh
$ zig run src/art.zig -lc
```

### REPL
The repl is very simple and responds to these commands:
- :q - quit
- key - adds 'key' with value = tree.size
- key number - adds key with value = parse(number)
- d:key - deletes key
- :r - reset (destroy and then init) the tree

A representation of the tree will be printed after each operation.

# Benchmarks
So far there is one benchark against StringHashMap from zig's standard library in [src/test_art.zig](src/test_art.zig#L689).  The test inserts, searches for and deletes each line from testdata/words.txt (235886 lines).

The results of the benchark on my machine:
```
StringHashMap
insert 599ms, search 573ms, delete 570ms, combined 1742ms
Art
insert 870ms, search 638ms, delete 702ms, combined 2212ms
```
| Operation| % difference |
| -- | --- |
|insert|45% slower|
|search|11% slower|
|delete|23% slower|
|overall|26% slower|

# References
- [the original c library: github.com/armon/libart](https://github.com/armon/libart)
- [The Adaptive Radix Tree: ARTful Indexing for Main-Memory Databases](http://www-db.in.tum.de/~leis/papers/ART.pdf)
