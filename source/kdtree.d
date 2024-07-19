/**
This module is based on https://github.com/DiddiZ/kdtree,
which is based on https://github.com/Mihail-K/kdtree.
*/
module kdtree;

import std.algorithm: map, sort, sum, swap;
import std.range: iota, zip;

struct KDNode(size_t k, T)
if(k > 0){
	private{
		const T[k] state;
		KDNode!(k, T)* left, right;
	}
	
	this(T[k] state...) nothrow @nogc pure @safe{
		this.state = state;
	}
	
	///Counts the number of elements in the kd tree.
	@property size_t length() const nothrow @nogc pure @safe =>
		&this is null ? 0 : left.length + right.length + 1;
	alias size = length;
	
	///Returns a newly created array of all elements in the kd tree.
	@property T[k][] elements() nothrow pure @safe =>
		&this is null ? [] : left.elements ~ state ~ right.elements;
}

///Creates a new kd tree.
template kdTree(size_t k, T){
	KDNode!(k, T)* kdTree() nothrow @nogc pure @safe =>
		null;
	
	KDNode!(k, T)* kdTree(T[k][] points, size_t depth=0) nothrow pure @safe{
		if(points.length == 0)
			return null;
		if(points.length == 1)
			return new KDNode!(k, T)(points[0]);
		
		const axis = depth % k, md = points.length / 2;
		
		quickSelect(points, axis, md);
		
		auto node = new KDNode!(k, T)(points[md]);
		node.left = kdTree(points[0..md], depth + 1);
		node.right = kdTree(points[md + 1..$], depth + 1);
		
		return node;
	}
	
	//Adapted from https://rosettacode.org/wiki/K-d_tree#Faster_Alternative_Version
	void quickSelect(T[k][] points, size_t axis, size_t k) nothrow @nogc pure @safe{
		size_t start = 0, end = points.length;
		if(end < 2)
			return;
		
		while(true){
			const pivot = points[k][axis];
			swap(points[k], points[end - 1]); //swaps the whole arrays x
			
			auto store = start;
			foreach(p; start..end){
				if(points[p][axis] < pivot){
					if(p != store){
						swap(points[p], points[store]);
					}
					store++;
				}
			}
			swap(points[store], points[end - 1]);
			
			if(points[store][axis] == points[k][axis])
				return; //median has duplicate values
			
			if(store > k)
				end = store;
			else
				start = store;
		}
	}
}

///Adds a new point to the kd tree.
void add(size_t k, T)(ref KDNode!(k, T)* root, const T[k] point, size_t depth=0) nothrow pure @safe{
	if(root is null){
		root = new KDNode!(k, T)(point);
		return;
	}
	
	auto axis = depth % k;
	if(point[axis] < root.state[axis]){
		root.left.add(point, depth + 1);
	}else{
		root.right.add(point, depth + 1);
	}
}

///Rebalances the kd tree by creating a new tree with the same elements
void rebalance(size_t k, T)(ref KDNode!(k, T)* root) nothrow pure @safe{
	root = kdTree(root.elements);
}

/**
Finds the nearest neighbour in the kd tree using euclidean distance metric.

`root` must not be null.
*/
const(T[k]) nearest(size_t k, T)(const KDNode!(k, T)* root, const T[k] point) nothrow @nogc pure @safe
in(root !is null, "tree is empty"){
	const(T[k])* nearest = null;
	double nearestDistance;
	
	static double distanceSq(ref const T[k] a, ref const T[k] b) nothrow @nogc pure @safe{
		double d = b[0] - a[0];
		double sum = d * d;
		static foreach(i; 1..k){
			d = b[i] - a[i];
			sum += d * d;
		}
		return sum;
	}
	
	void nearestImpl(const KDNode!(k, T)* current, ref const T[k] point, size_t depth=0){
		if(current !is null){
			const axis = depth % k;
			const distance = distanceSq(current.state, point);
			
			if(nearest is null || distance < nearestDistance){
				nearestDistance = distance;
				nearest = &current.state;
			}
			
			if(nearestDistance > 0){
				const distanceAxis = (current.state[axis] - point[axis]);
				
				nearestImpl(distanceAxis > 0 ? current.left : current.right, point, depth+1);
				
				if(distanceAxis * distanceAxis <= nearestDistance){
					nearestImpl(distanceAxis > 0 ? current.right : current.left, point, depth+1);
				}
			}
		}
	}
	
	nearestImpl(root, point);
	return *nearest;
}

unittest{
	auto root = kdTree([[0, 0], [1, 1], [1, 0], [0, 1]]);
	
	assert(root.nearest([0, 0]) == [0, 0]);
	assert(root.nearest([1, 1]) == [1, 1]);
	assert(root.nearest([-3, 5]) == [0, 1]);
	assert(root.nearest([25, -4]) == [1, 0]);
	
	root.add([25, 0]);
	assert(root.nearest([25, -4]) == [25, 0]);
}

///Test build and nearest
unittest{
	import std.algorithm: minElement;
	import std.numeric: euclideanDistance;
	import std.random: uniform01;
	
	auto points = new double[3][1000];
	foreach(i; 0..points.length){
		foreach(j; 0..points[i].length){
			points[i][j] = uniform01;
		}
	}
	
	auto root = kdTree(points);
	assert(root.length == points.length);
	
	foreach(_; 0..1000){
		double[3] point = [uniform01, uniform01, uniform01];
		
		assert(root.nearest(point) == points.minElement!(a => a[0..$].euclideanDistance(point[0..$])));
	}
}

///Test add and nearest
unittest{
	import std.algorithm: minElement;
	import std.numeric: euclideanDistance;
	import std.random: uniform01;
	
	auto points = new double[3][1000];
	foreach(i; 0..points.length){
		foreach(j; 0..points[i].length){
			points[i][j] = uniform01;
		}
	}
	
	auto root = kdTree!(3, double);
	foreach(i; 0..points.length){
		root.add(points[i]);
	}
	assert(root.length == points.length);
	
	foreach(_; 0..1000){
		double[3] point = [uniform01, uniform01, uniform01];
		
		assert(root.nearest(point) == points.minElement!(a => a[].euclideanDistance(point[])));
	}
}

///Test rebalance
unittest{
	import std.algorithm: minElement;
	import std.numeric: euclideanDistance;
	import std.random: uniform01;
	
	auto points = new double[3][1000];
	foreach(i; 0..points.length){
		foreach(j; 0..points[i].length){
			points[i][j] = uniform01;
		}
	}
	
	auto root = kdTree!(3, double);
	foreach(i; 0..points.length){
		root.add(points[i]);
	}
	assert(root.length == points.length);
	
	root.rebalance();
	assert(root.length == points.length);
	
	foreach(_; 0..1000){
		double[3] point = [uniform01, uniform01, uniform01];
		
		assert(root.nearest(point) == points.minElement!(a => a[].euclideanDistance(point[])));
	}
}

///Test nearest on empty tree
unittest{
	import core.exception: AssertError;
	import std.exception: assertThrown;
	
	auto root = kdTree!(3, double);
	assertThrown!AssertError(root.nearest([0.0, 0.0, 0.0]));
}
