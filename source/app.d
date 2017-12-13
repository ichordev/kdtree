import std.stdio;
import kdtree;

void main() {
	benchmarkNearest();
	benchmarkGrowing();
}

void benchmarkNearest() {
	import fluent.asserts : should;
	import std.stdio : writeln;
	import std.random : uniform01;
	import std.datetime.stopwatch : benchmark;

	enum dim = 3;
	enum numPoints = 1000;
	enum numTestPoints = 100;

	auto points = new double[dim][numPoints];
	foreach (i; 0 .. points.length) {
		foreach (j; 0 .. points[i].length) {
			points[i][j] = uniform01;
		}
	}
	auto testPoints = new double[dim][numTestPoints];
	foreach (i; 0 .. testPoints.length) {
		foreach (j; 0 .. testPoints[i].length) {
			testPoints[i][j] = uniform01;
		}
	}

	static double nearestNaive(size_t k, T)(T[k][] points, in T[k][] testPoints) {
		import std.algorithm : minElement;
		import std.numeric : euclideanDistance;

		auto sum = 0.0;
		foreach (point; testPoints) {
			auto nearest = points.minElement!(a => a[].euclideanDistance(point[]));
			sum += nearest[0];
		}
		return sum;
	}

	static double nearestKdTree(size_t k, T)(T[k][] points, in T[k][] testPoints) {
		auto root = kdTree(points);

		auto sum = 0.0;
		foreach (point; testPoints) {
			auto nearest = root.nearest(point);
			sum += nearest[0];
		}
		return sum;
	}

	static double nearestKdTreeAdd(size_t k, T)(T[k][] points, in T[k][] testPoints) {
		auto root = kdTree!(k, T);

		foreach (point; points) {
			root.add(point);
		}

		auto sum = 0.0;
		foreach (point; testPoints) {
			auto nearest = root.nearest(point);
			sum += nearest[0];
		}
		return sum;
	}

	double sum1 = 0, sum2 = 0, sum3 = 0;
	auto results = benchmark!({ sum1 += nearestNaive(points, testPoints); }, { sum2 += nearestKdTree(points, testPoints); }, { sum3 += nearestKdTreeAdd(points, testPoints); })(10);
	sum2.should.equal(sum1);
	sum3.should.equal(sum1);

	writeln("Naive: ", results[0], " ", " Kd: ", results[1], " Kd-Add: ", results[2]);
}

void benchmarkGrowing() {
	import fluent.asserts : should;
	import std.stdio : writeln;
	import std.random : uniform01;
	import std.datetime.stopwatch : benchmark;

	enum dim = 5;
	enum numPoints = 1000;

	auto points = new double[dim][numPoints];
	foreach (i; 0 .. points.length) {
		foreach (j; 0 .. points[i].length) {
			points[i][j] = uniform01;
		}
	}
	auto testPoints = new double[dim][numPoints];
	foreach (i; 0 .. testPoints.length) {
		foreach (j; 0 .. testPoints[i].length) {
			testPoints[i][j] = uniform01;
		}
	}

	static double nearestNaive(size_t k, T)(T[k][] points, in T[k][] testPoints) {
		import std.algorithm : minElement;
		import std.numeric : euclideanDistance;

		auto sum = 0.0;
		foreach (i; 0 .. points.length) {
			auto nearest = points[0 .. i + 1].minElement!(a => a[].euclideanDistance(testPoints[i][]));
			sum += nearest[0];
		}
		return sum;
	}

	static double nearestAdd(size_t k, T)(T[k][] points, in T[k][] testPoints) {
		auto root = kdTree!(k, T);

		auto sum = 0.0;
		foreach (i; 0 .. points.length) {
			root.add(points[i]);
			auto nearest = root.nearest(testPoints[i]);
			sum += nearest[0];
		}
		return sum;
	}

	static double nearestAddRebalance(size_t k, T)(T[k][] points, in T[k][] testPoints) {
		auto root = kdTree!(k, T);

		auto sum = 0.0;
		foreach (i; 0 .. points.length) {
			root.add(points[i]);
			if (i % 100000 == 0) {
				root.rebalance();
			}

			auto nearest = root.nearest(testPoints[i]);
			sum += nearest[0];
		}
		return sum;
	}

	double sum1 = 0, sum2 = 0, sum3 = 0;
	auto results = benchmark!({ sum1 += nearestNaive(points, testPoints); }, { sum2 += nearestAdd(points, testPoints); }, { sum3 += nearestAddRebalance(points, testPoints); })(1);
	sum2.should.equal(sum1);
	sum3.should.equal(sum1);

	writeln("Naive: ", results[0], " ", " Add: ", results[1], " Rebalance: ", results[2]);
}
