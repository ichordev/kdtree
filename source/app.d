import std.stdio;
import std.datetime.stopwatch : benchmark;
import kdtree;

void main() {
	benchmarkNearest();
	benchmarkGrowing();
}

private double[dim][] randomPoints(size_t dim)(size_t numPoints) {
	import std.random : uniform01;

	auto points = new double[dim][numPoints];
	foreach (i; 0 .. points.length) {
		foreach (j; 0 .. points[i].length) {
			points[i][j] = uniform01;
		}
	}
	return points;
}

private double[5][] pointsFromFile(string path, size_t numPoints) {
	import std.algorithm : joiner;
	import std.csv : csvReader;
	import std.typecons : Tuple;

	double[5][] points;
	auto file = File(path, "r");
	scope (exit)
		file.close();

	foreach (record; file.byLine.joiner("\n").csvReader!(Tuple!(double, double, double, double, double))) {
		double[5] point = [record[0], record[1], record[2], record[3], record[4]];
		points ~= point;

		if (points.length == numPoints) {
			break;
		}
	}
	return points;
}

/// Test pointsFromFile
unittest {
	import fluent.asserts : should;

	auto points = pointsFromFile("species.csv", 10);

	points.length.should.equal(10);
	points[0].should.equal([0, 0.4474427700042725, 0, 0.9130669832229614, 0.9997519850730896]);
	points[$ - 1].should.equal([3.31227707862854, 0.9355245232582092, 0.4000000059604645, 0.9130669832229614, 0.9997519850730896]);
}

/**
	Benchmarks finding x nearest neighbors of y points.
	Benchmarks include time for creating the kd trees, if used.
	A dataset of random points is used.
*/
void benchmarkNearest() {
	import fluent.asserts : should;

	enum dim = 3;
	enum numPoints = 1000;
	enum numTestPoints = 100;

	auto points = randomPoints!dim(numPoints);
	auto testPoints = randomPoints!dim(numTestPoints);

	/// Find nearest neighbour naively by comparing all distances.
	static double nearestNaive(size_t k, T)(T[k][] points, in T[k][] testPoints) {
		import std.algorithm : minElement;
		import std.numeric : euclideanDistance;

		auto sum = 0.0;
		foreach (ref point; testPoints) {
			auto nearest = points.minElement!(a => a[].euclideanDistance(point[]));
			sum += nearest[0];
		}
		return sum;
	}

	/// Create kdtree knowing all points.
	static double nearestKdTree(size_t k, T)(T[k][] points, in T[k][] testPoints) {
		auto root = kdTree(points);

		auto sum = 0.0;
		foreach (ref point; testPoints) {
			auto nearest = root.nearest(point);
			sum += nearest[0];
		}
		return sum;
	}

	/// Grow kdtree by adding all points. If data is biased, the tree should become unbalanced.
	static double nearestKdTreeAdd(size_t k, T)(T[k][] points, in T[k][] testPoints) {
		auto root = kdTree!(k, T);

		foreach (ref point; points) {
			root.add(point);
		}

		auto sum = 0.0;
		foreach (ref point; testPoints) {
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

/**
	Benchmarks finding nearest neighbors of points while adding these points to the set after adding.
	Benchmarks include time for creating the kd trees, if used.
	A dataset of random points is used.
*/
void benchmarkGrowing() {
	import fluent.asserts : should;
	import std.stdio : writeln;
	import std.random : uniform01;
	import std.datetime.stopwatch : benchmark;

	enum dim = 5;
	enum numPoints = 1000;

	auto points = randomPoints!dim(numPoints);

	/// Find nearest neighbour naively by comparing all distances.
	static double nearestNaive(size_t k, T)(T[k][] points) {
		import std.algorithm : minElement;
		import std.numeric : euclideanDistance;

		auto sum = 0.0;
		foreach (i; 1 .. points.length) {
			auto nearest = points[0 .. i].minElement!(a => a[].euclideanDistance(points[i][]));
			sum += nearest[0];
		}
		return sum;
	}

	/// Use kd tree and add each point after finding the nearest neighbor.
	static double nearestAdd(size_t k, T)(T[k][] points) {
		auto root = kdTree([points[0]]);

		auto sum = 0.0;
		foreach (i; 1 .. points.length) {
			auto nearest = root.nearest(points[i]);
			root.add(points[i]);
			sum += nearest[0];
		}
		return sum;
	}

	/// Use kd tree and add each point after finding the nearest neighbor. Repalances the kd tree after 100000 insertions.
	static double nearestAddRebalance(size_t k, T)(T[k][] points) {
		auto root = kdTree([points[0]]);

		auto sum = 0.0;
		foreach (i; 1 .. points.length) {
			auto nearest = root.nearest(points[i]);

			root.add(points[i]);
			if (i % 100000 == 0) {
				root.rebalance();
			}

			sum += nearest[0];
		}
		return sum;
	}

	double sum1 = 0, sum2 = 0, sum3 = 0;
	auto results = benchmark!({ sum1 += nearestNaive(points); }, { sum2 += nearestAdd(points); }, { sum3 += nearestAddRebalance(points); })(1);
	sum2.should.equal(sum1);
	sum3.should.equal(sum1);

	writeln("Naive: ", results[0], " ", " Add: ", results[1], " Rebalance: ", results[2]);
}
