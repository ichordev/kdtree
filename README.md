# kdtree
A k-dimensional tree implementation for D.

## Example Code

```d
import kdtree;

void main()
{
    // Construct a 2-Dimensional tree of integers:
    auto root = kdTree([[0, 0], [1, 1], [1, 0], [0, 1]]);

    // Find the node closest to (-3, 5):
    auto near = tree.nearest([-3, 5]);
    assert(near == [0, 1]);

    // Add new point (25, 0):
    root.add([25, 0]);
}
```

## Caveats

kdtree is currently not intended for altering constructed trees. It's limited to constructing trees from a series of data points, adding new points and performing nearest-neighbour lookups. It is not possible to remove points.

## License

MIT
