import js.lib.Promise;

using Lambda;

class Utils {
	static final matchNum = ~/[0-9]+/g;

	public static function numericStringSort(s1:String, s2:String):Int {
		if (matchNum.match(s1) && matchNum.match(s2)) {
			final m1 = getMatches(matchNum, s1);
			final m2 = getMatches(matchNum, s2);
			for (i in 0...m1.length) {
				if (m1[i] == null || m2[i] == null) continue;
				final n1 = Std.parseInt(m1[i]);
				final n2 = Std.parseInt(m2[i]);
				if (n1 == n2) continue;
				return n1 < n2 ? -1 : 1;
			}
		}
		return s1 < s2 ? -1 : 1;
	}

	public static function getMatches(ereg:EReg, input:String, index = 0):Array<String> {
		final matches = [];
		while (ereg.match(input)) {
			matches.push(ereg.matched(index));
			input = ereg.matchedRight();
		}
		return matches;
	}

	public static function promiseSequence(arr:Array<() -> Promise<Any>>):Promise<Any> {
		var promise = Promise.resolve(null);
		for (job in arr) {
			promise = promise.then(_ -> job());
		}
		return promise;
	}
}
