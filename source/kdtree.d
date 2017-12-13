/**
	This module is based on https://github.com/Mihail-K/kdtree.
*/
module kdtree;

import std.algorithm : map, sum, sort;
import std.range : iota, zip;

struct KDNode(size_t k, T) if (k > 0) {
	private const(T[k]) state;
	private KDNode!(k, T)* left = null, right = null;

	this(T[k] state...) {
		this.state = state;
	}
}

/**
	Counts the number of elements in the kd tree.
*/
size_t size(size_t k, T)(KDNode!(k, T)* node) {
	if (node is null) {
		return 0;
	}

	return node.left.size + node.right.size + 1;
}

/**
	Creates a slice of all elements in the kd tree.
*/
T[k][] elements(size_t k, T)(KDNode!(k, T)* node) {
	if (node is null) {
		return [];
	}

	return node.left.elements ~ node.state ~ node.right.elements; // Preserve order
}

/**
	Creates a new kd tree.
*/
template kdTree(size_t k, T) {
	KDNode!(k, T)* kdTree() {
		return null;
	}

	KDNode!(k, T)* kdTree(T[k][] points, size_t depth = 0) {
		if (points.length == 0) {
			return null;
		}
		if (points.length == 1) {
			return new KDNode!(k, T)(points[0]);
		}

		immutable axis = depth % k;

		points.sort!((a, b) => a[axis] < b[axis]);

		auto node = new KDNode!(k, T)(points[$ / 2]);
		node.left = kdTree(points[0 .. $ / 2], depth + 1);
		node.right = kdTree(points[$ / 2 + 1 .. $], depth + 1);

		return node;
	}
}

/**
	Adds a new point to the kd tree.
*/
void add(size_t k, T)(ref KDNode!(k, T)* root, in T[k] point, size_t depth = 0) {
	if (root is null) {
		root = new KDNode!(k, T)(point);
		return;
	}

	auto axis = depth % k;
	if (point[axis] < root.state[axis]) {
		root.left.add(point, depth + 1);
	} else {
		root.right.add(point, depth + 1);
	}
}

/**
	Rebalances the kd tree by creating a new tree with the same elements
*/
void rebalance(size_t k, T)(ref KDNode!(k, T)* root) {
	root = kdTree(root.elements);
}

/**
	Finds the neares neighbor in the kd tree using euclidean distance metric.
	root must not be empty.
*/
const(T[k]) nearest(size_t k, T)(in KDNode!(k, T)* root, in auto ref T[k] point)
in {
	assert (root !is null, "tree is empty");
}
body {
	const(T[k])* nearest = null;
	double nearestDistance;

	static double distanceSq(in T[k] a, in T[k] b) {
		double sum = (b[0] - a[0]) ^^ 2;
		static foreach (i; 1 .. k) {
			sum += (b[i] - a[i]) ^^ 2;
		}
		return sum;
	}

	void nearestImpl(in KDNode!(k, T)* current, in ref T[k] point, size_t depth = 0) {
		if (current !is null) {
			immutable axis = depth % k;
			immutable distance = distanceSq(current.state, point);

			if (nearest is null || distance < nearestDistance) {
				nearestDistance = distance;
				nearest = &current.state;
			}

			if (nearestDistance > 0) {
				immutable distanceAxis = (current.state[axis] - point[axis]);

				nearestImpl(distanceAxis > 0 ? current.left : current.right, point, depth + 1);

				if (distanceAxis ^^ 2 <= nearestDistance) {
					nearestImpl(distanceAxis > 0 ? current.right : current.left, point, depth + 1);
				}
			}
		}
	}

	nearestImpl(root, point);
	return *nearest;
}

unittest {
	import fluent.asserts : should;

	auto root = kdTree([[0, 0], [1, 1], [1, 0], [0, 1]]);

	root.nearest([0, 0]).should.equal([0, 0]);
	root.nearest([1, 1]).should.equal([1, 1]);
	root.nearest([-3, 5]).should.equal([0, 1]);
	root.nearest([25, -4]).should.equal([1, 0]);

	root.add([25, 0]);
	root.nearest([25, -4]).should.equal([25, 0]);
}

/// Test build and nearest
unittest {
	import fluent.asserts : should;
	import std.algorithm : minElement;
	import std.numeric : euclideanDistance;
	import std.random : uniform01;

	auto points = new double[3][1000];
	foreach (i; 0 .. points.length) {
		foreach (j; 0 .. points[i].length) {
			points[i][j] = uniform01;
		}
	}

	auto root = kdTree(points);
	root.size.should.equal(points.length);

	foreach (_; 0 .. 1000) {
		double[3] point = [uniform01, uniform01, uniform01];

		root.nearest(point).should.equal(points.minElement!(a => a[0 .. $].euclideanDistance(point[0 .. $])));
	}
}

/// Test add and nearest
unittest {
	import fluent.asserts : should;
	import std.algorithm : minElement;
	import std.numeric : euclideanDistance;
	import std.random : uniform01;

	auto points = new double[3][1000];
	foreach (i; 0 .. points.length) {
		foreach (j; 0 .. points[i].length) {
			points[i][j] = uniform01;
		}
	}

	auto root = kdTree!(3, double);
	foreach (i; 0 .. points.length) {
		root.add(points[i]);
	}
	root.size.should.equal(points.length);

	foreach (_; 0 .. 1000) {
		double[3] point = [uniform01, uniform01, uniform01];

		root.nearest(point).should.equal(points.minElement!(a => a[0 .. $].euclideanDistance(point[0 .. $])));
	}
}

/// Test rebalance
unittest {
	import fluent.asserts : should;
	import std.algorithm : minElement;
	import std.numeric : euclideanDistance;
	import std.random : uniform01;

	auto points = new double[3][1000];
	foreach (i; 0 .. points.length) {
		foreach (j; 0 .. points[i].length) {
			points[i][j] = uniform01;
		}
	}

	auto root = kdTree!(3, double);
	foreach (i; 0 .. points.length) {
		root.add(points[i]);
	}
	root.size.should.equal(points.length);

	root.rebalance();
	root.size.should.equal(points.length);

	foreach (_; 0 .. 1000) {
		double[3] point = [uniform01, uniform01, uniform01];

		root.nearest(point).should.equal(points.minElement!(a => a[0 .. $].euclideanDistance(point[0 .. $])));
	}
}

/// Test nearest on empty tree
unittest {
	import fluent.asserts : should;
	import core.exception : AssertError;

	auto root = kdTree!(3, double);
	root.nearest([0.0, 0.0, 0.0]).should.throwException!AssertError.withMessage.equal("tree is empty");
}
