
module kdtree.point;

import std.algorithm;
import std.array;
import std.range;

struct KDPoint(size_t k, T)
{
    T[k] state;

    this(T[k] state...)
    {
        this.state = state;
    }

    static KDPoint!(k, T)[] build(T[k][] points...)
    {
        return points.map!(p => KDPoint!(k, T)(p)).array;
    }

    double distanceSq(KDPoint!(k, T) other) const
    {
        return iota(0, k).map!(i => state[i]).sum;
    }

    @property
    enum size_t length = k;

    T opIndex(size_t axis)
    {
        return state[axis];
    }

    T[] opSlice(size_t start, size_t stop)
    {
        return state[start .. stop];
    }
}

@property
KDPoint!(k, T) kdPoint(size_t k, T)(T[k] point)
{
    return KDPoint!(k, T)(point);
}

@property
KDPoint!(k, T) kdPoint(size_t k, T)(T[] point)
{
    return KDPoint!(k, T)(point[0 .. k]);
}

@property
KDPoint!(k, T)[] sortedOn(size_t k, T)(KDPoint!(k, T)[] points, size_t axis)
{
    return points.sort!((a, b) => a[axis] < b[axis]).array;
}