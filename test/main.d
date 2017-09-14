

import BDD;

unittest {
	import lru_eviction_queue;

	describe("LRUEvictionQueue",
		it("Should add, update, and remove item", delegate() {
			// Init
			auto cache = LRUEvictionQueue!(string, int)(size_t.max);
			cache.max_length.shouldEqual(size_t.max);

			// Empty
			cache.length.shouldEqual(0);
			cache.hasKey("count").shouldEqual(false);

			// Add
			cache["count"] = 65;
			cache["count"].shouldEqual(65);
			cache.length.shouldEqual(1);
			cache.hasKey("count").shouldEqual(true);

			// Update
			cache["count"] = 97;
			cache["count"].shouldEqual(97);
			cache.length.shouldEqual(1);
			cache.hasKey("count").shouldEqual(true);

			// Remove
			cache.remove("count");
			cache.get("count", -1).shouldEqual(-1);
			cache.length.shouldEqual(0);
			cache.hasKey("count").shouldEqual(false);
		}),
		it("Should work with strings", delegate() {
			// Init
			auto cache = LRUEvictionQueue!(string, string)(size_t.max);
			cache.max_length.shouldEqual(size_t.max);

			// Empty
			cache.length.shouldEqual(0);
			cache.hasKey("name").shouldEqual(false);

			// Add
			cache["name"] = "bobrick";
			cache["name"].shouldEqual("bobrick");
			cache.length.shouldEqual(1);
			cache.hasKey("name").shouldEqual(true);

			// Update
			cache["name"] = "frankrick";
			cache["name"].shouldEqual("frankrick");
			cache.length.shouldEqual(1);
			cache.hasKey("name").shouldEqual(true);

			// Remove
			cache.remove("name");
			cache.get("name", string.init).shouldEqual(string.init);
			cache.length.shouldEqual(0);
			cache.hasKey("name").shouldEqual(false);
		}),
		it("Should throw with invalid max size", delegate() {
			shouldThrow(delegate() {
				auto cache = LRUEvictionQueue!(string, string)(0);
			}, "Cannot have a max_length less than 1.");
		}),
		it("Should save items in order added", delegate() {
			import std.algorithm.sorting : sort;
			auto cache = LRUEvictionQueue!(int, string)(3);
			cache.max_length.shouldEqual(3);

			// Add 4 items
			cache[99] = "Tim";
			cache[22] = "Al";
			cache[44] = "Heidi";
			cache.length.shouldEqual(3);

			// Make sure the keys are in order added
			cache.keys.shouldEqual([44, 22, 99]);
		}),
		it("Should evict first items", delegate() {
			auto cache = LRUEvictionQueue!(string, string)(3);
			cache.max_length.shouldEqual(3);

			// Add 4 items
			cache["1"] = "Tim";
			cache["2"] = "Al";
			cache["3"] = "Heidi";
			cache["4"] = "Wilson";
			cache.length.shouldEqual(3);

			// Make sure the last 3 items are the only keys now
			cache.keys.shouldEqual(["4", "3", "2"]);
		}),
		it("Should reorder items after Get", delegate() {
			auto cache = LRUEvictionQueue!(string, string)(4);
			cache.max_length.shouldEqual(4);

			// Add 4 items
			cache["1"] = "Tim";
			cache["2"] = "Al";
			cache["3"] = "Heidi";
			cache["4"] = "Wilson";
			cache.length.shouldEqual(4);

			cache.get("2", string.init);

			// Make sure the keys are now reordered
			cache.keys.shouldEqual(["2", "4", "3", "1"]);
		}),
		it("Should reorder items after Set", delegate() {
			auto cache = LRUEvictionQueue!(string, string)(4);
			cache.max_length.shouldEqual(4);

			// Add 4 items
			cache["1"] = "Tim";
			cache["2"] = "Al";
			cache["3"] = "Heidi";
			cache["4"] = "Wilson";
			cache.length.shouldEqual(4);

			cache.set("3", "Lisa");

			// Make sure item 3 was moved to head
			cache.keys.shouldEqual(["3", "4", "2", "1"]);
		}),
		it("Should fire event on eviction", delegate() {
			auto cache = LRUEvictionQueue!(string, string)(2);
			cache.max_length.shouldEqual(2);

			string[] evictions;
			string[] changes;
			cache.on_evict_cb = delegate(string key, string value) {
				evictions ~= key;
			};
			cache.on_update_cb = delegate(string key, string value) {
				changes ~= key;
			};

			cache["1"] = "Tim";
			cache["2"] = "Al";
			evictions.shouldEqual([]);

			cache["3"] = "Heidi";
			evictions.shouldEqual(["1"]);

			cache["4"] = "Wilson";
			evictions.shouldEqual(["1", "2"]);

			cache["3"] = "Lisa";
			evictions.shouldEqual(["1", "2"]);
			changes.shouldEqual(["3"]);

			cache.get("1", string.init);
			evictions.shouldEqual(["1", "2"]);
			changes.shouldEqual(["3"]);
		}),
		it("Should work with foreach", delegate() {
			auto cache = LRUEvictionQueue!(string, string)(3);
			cache.max_length.shouldEqual(3);

			cache["1"] = "Tim";
			cache["2"] = "Al";
			cache["3"] = "Heidi";

			string[] keys;
			string[] values;
			foreach (key, value ; cache) {
				keys ~= key;
				values ~= value;
			}

			keys.shouldEqual(["3", "2", "1"]);
			values.shouldEqual(["Heidi", "Al", "Tim"]);
		}),
		it("Should work with in", delegate() {
			auto cache = LRUEvictionQueue!(string, int)(3);
			cache["count"] = 3;

			int* value = "count" in cache;
			shouldEqual(*value, 3);

			value = "nope" in cache;
			shouldEqual(value, null);
		}),
	);
}

int main() {
	return BDD.printResults();
}
