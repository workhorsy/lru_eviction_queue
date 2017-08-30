// Copyright (c) 2017 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// A LRU Eviction Queue for the D programming language
// https://github.com/workhorsy/lru_eviction_queue

/++
A LRU Eviction Queue for the D programming language

Home page:
$(LINK https://github.com/workhorsy/lru_eviction_queue)

License:
Boost Software License - Version 1.0

Examples:
----
import lru_eviction_queue;
import std.stdio : stdout;

// Create a queue that will hold 3 items
auto cache = LRUEvictionQueue!int(3);

cache.on_evict_cb = delegate(string key, int value) {
	stdout.writefln("Evicted item: %s", key);
};
cache.on_update_cb = delegate(string key, int value) {
	stdout.writefln("Updated item: %s", key);
};

// Add
cache["aaa"] = 65;
cache["bbb"] = 97;
cache["ccc"] = 15;
cache["ddd"] = 46;

if (! cache.HasKey("aaa")) {
	stdout.writefln("Item \"aaa\" was evicted!");
}
----
+/


struct LRUEvictionQueue(T) {
	import std.container : SList;

	/++
	Creates a LRUEvictionQueue

	Params:
	 max_length = The max size of the queue. After this many items are added, the oldest items will be removed.

	Throws:
	 If max_length is less than 1, it will throw an Exception.

	Examples:
	----
	auto cache = LRUEvictionQueue!string(100);
	----
	+/
	this(ulong max_length) {
		// Make sure the args are valid
		if (max_length < 1) {
			throw new Exception("Cannot have a max_length less than 1.");
		}

		this._max_length = max_length;
		this._expiration_list = SList!string();
	}

	/++
	Returns true if a key is still on the queue

	Params:
	 key = The name of the key to check.

	Examples:
	----
	auto cache = LRUEvictionQueue!string(100);
	bool retval = cache.HasKey("name");
	----
	+/
	bool HasKey(string key) {
		return (key in this._cache) != null;
	}

	/++
	Sets the value in the queue

	Params:
	 key = The key to set.
	 value = The value to set.

	Examples:
	----
	auto cache = LRUEvictionQueue!string(100);
	cache.set("name", "Bob");
	----
	+/
	void set(string key, T value) {
		import std.range : take, walkLength;
		import std.array : array;
		import std.algorithm : find;

		// If the key is already used, update the value
		if (key in this._cache) {
			auto r = find(this._expiration_list[], key).take(1);
			this._expiration_list.stableLinearRemove(r);
			this._expiration_list.stableInsertFront(r);

			if (on_update_cb) {
				auto old_value = this._cache[key];
				on_update_cb(key, old_value);
			}

			this._cache[key] = value;

			return;
		}

		// If the size will be greater than the max, remove the oldest element
		if (walkLength(this._expiration_list[]) + 1 > this._max_length) {
			auto remove_key = this._expiration_list.front();
			this.evictElement(remove_key);
		}

		// If the key is new, add the new entry
		this._expiration_list.stableInsertAfter(this._expiration_list[], key);
		this._cache[key] = value;
	}

	/++
	Gets the value in the queue

	Params:
	 key = The key to get.
	 default_value = The value returned if the key is not found.

	Examples:
	----
	auto cache = LRUEvictionQueue!string(100);
	string name = cache.get("name", string.init);
	----
	+/
	T get(string key, T default_value) {
		import std.range : take;
		import std.algorithm : find;

		// If it has the key, return the value
		if (key in this._cache) {
			auto r = find(this._expiration_list[], key).take(1);
			this._expiration_list.stableLinearRemove(r);
			this._expiration_list.stableInsertFront(r);

			return this._cache[key];
		}

		return default_value;
	}

	/++
	Removes the key from the queue. Does nothing if the key is not in the queue. 
	 Will not fire any events.

	Params:
	 key = The key to remove.

	Examples:
	----
	auto cache = LRUEvictionQueue!string(100);
	cache["name"] = "Alice";
	cache.remove("name");
	----
	+/
	void remove(string key) {
		import std.range : take;
		import std.algorithm : find;

		if (key in this._cache) {
			// Remove the element from the expiration list
			auto r = find(this._expiration_list[], key).take(1);
			this._expiration_list.stableLinearRemove(r);

			// Remove the item from the cache
			this._cache.remove(key);
		}
	}

	/++
	Removes all the items from the queue. Will not fire any events.

	Examples:
	----
	auto cache = LRUEvictionQueue!string(100);
	cache["name"] = "Tim";
	cache.clear();
	----
	+/
	void clear() {
		this._expiration_list.clear();
		this._cache.clear();
	}

	private void evictElement(string key) {
		import std.range : take;
		import std.algorithm : find;

		// Fire the on evict callback
		if (this.on_evict_cb) {
			this.on_evict_cb(key, this._cache[key]);
		}

		// Remove the element from the expiration list
		auto r = find(this._expiration_list[], key).take(1);
		this._expiration_list.stableLinearRemove(r);

		// Remove the item from the cache
		this._cache.remove(key);
	}

	/++
	Returns the length of the queue.

	Examples:
	----
	auto cache = LRUEvictionQueue!string(100);
	cache["name"] = "Alice";
	ulong len = cache.length;
	----
	+/
	ulong length() {
		return this._cache.length;
	}

	/++
	Returns the max length of the queue before items are removed.

	Examples:
	----
	auto cache = LRUEvictionQueue!string(100);
	ulong max_len = cache.max_length;
	----
	+/
	ulong max_length() {
		return this._max_length;
	}

	/++
	Returns all the keys in the queue.

	Examples:
	----
	auto cache = LRUEvictionQueue!int(100);
	cache["bbb"] = 5;
	cache["zzz"] = 7;
	string[] keys = cache.keys();
	----
	+/
	string[] keys() {
		import std.array : array;
		return array(this._expiration_list);
	}

	/++
	Used to iterate over the queue.

	Examples:
	----
	auto cache = LRUEvictionQueue!int(100);
	cache["bbb"] = 5;
	cache["zzz"] = 7;
	foreach (key, value ; cache) {
	
	}
	----
	+/
	int opApply(scope int delegate(ref string key, T value) dg) {
		int result = 0;

		foreach (key, value ; _cache) {
			result = dg(key, value);
			if (result)
				break;
		}
		return result;
	}

	/++
	Gets the value in the queue. Throws if the key is not found.

	Params:
	 key = The key to get.

	 Throws:
 	 If the key is not found, it will throw an Exception.

	Examples:
	----
	auto cache = LRUEvictionQueue!string(100);
	cache["name"] = "Frank";
	string name = cache["name"];
	----
	+/
	T opIndex(string key) {
		import std.string : format;

		T retval = this.get(key, T.init);
		if (retval !is T.init) {
			return retval;
		}

		throw new Exception("Invalid index '%s'.".format(key));
	}

	/++
	Sets the value in the queue

	Params:
	 key = The key to set.
	 value = The value to set.

	Examples:
	----
	auto cache = LRUEvictionQueue!string(100);
	cache["name"] = "Lisa";
	----
	+/
	T opIndexAssign(T value, string key) {
		this.set(key, value);
		return value;
	}

	ulong _max_length;
	SList!string _expiration_list;
	T[string] _cache;
	void delegate(string key, T value) on_evict_cb;
	void delegate(string key, T value) on_update_cb;
}

unittest {
	import BDD;
	describe("lru_cache",
		it("Should add, update, and remove item", delegate() {
			// Init
			auto cache = LRUEvictionQueue!int(ulong.max);
			cache.max_length.shouldEqual(ulong.max);

			// Empty
			cache.length.shouldEqual(0);
			cache.HasKey("count").shouldEqual(false);

			// Add
			cache["count"] = 65;
			cache["count"].shouldEqual(65);
			cache.length.shouldEqual(1);
			cache.HasKey("count").shouldEqual(true);

			// Update
			cache["count"] = 97;
			cache["count"].shouldEqual(97);
			cache.length.shouldEqual(1);
			cache.HasKey("count").shouldEqual(true);

			// Remove
			cache.remove("count");
			cache.get("count", -1).shouldEqual(-1);
			cache.length.shouldEqual(0);
			cache.HasKey("count").shouldEqual(false);
		}),
		it("Should work with strings", delegate() {
			// Init
			auto cache = LRUEvictionQueue!string(ulong.max);
			cache.max_length.shouldEqual(ulong.max);

			// Empty
			cache.length.shouldEqual(0);
			cache.HasKey("name").shouldEqual(false);

			// Add
			cache["name"] = "bobrick";
			cache["name"].shouldEqual("bobrick");
			cache.length.shouldEqual(1);
			cache.HasKey("name").shouldEqual(true);

			// Update
			cache["name"] = "frankrick";
			cache["name"].shouldEqual("frankrick");
			cache.length.shouldEqual(1);
			cache.HasKey("name").shouldEqual(true);

			// Remove
			cache.remove("name");
			cache.get("name", string.init).shouldEqual(string.init);
			cache.length.shouldEqual(0);
			cache.HasKey("name").shouldEqual(false);
		}),
		it("Should throw with invalid max size", delegate() {
			shouldThrow(delegate() {
				auto cache = LRUEvictionQueue!string(0);
			}, "Cannot have a max_length less than 1.");
		}),
		it("Should save items in order added", delegate() {
			import std.algorithm.sorting : sort;
			auto cache = LRUEvictionQueue!string(3);
			cache.max_length.shouldEqual(3);

			// Add 4 items
			cache["1"] = "Tim";
			cache["2"] = "Al";
			cache["3"] = "Heidi";
			cache.length.shouldEqual(3);

			// Make sure the keys are in order added
			cache.keys.shouldEqual(["1", "2", "3"]);
		}),
		it("Should evict first items", delegate() {
			auto cache = LRUEvictionQueue!string(3);
			cache.max_length.shouldEqual(3);

			// Add 4 items
			cache["1"] = "Tim";
			cache["2"] = "Al";
			cache["3"] = "Heidi";
			cache["4"] = "Wilson";
			cache.length.shouldEqual(3);

			// Make sure the last 3 items are the only keys now
			cache.keys.shouldEqual(["2", "3", "4"]);
		}),
		it("Should reorder items after Get", delegate() {
			auto cache = LRUEvictionQueue!string(4);
			cache.max_length.shouldEqual(4);

			// Add 4 items
			cache["1"] = "Tim";
			cache["2"] = "Al";
			cache["3"] = "Heidi";
			cache["4"] = "Wilson";
			cache.length.shouldEqual(4);

			cache.get("2", string.init);

			// Make sure the keys are now reordered
			cache.keys.shouldEqual(["2", "1", "3", "4"]);
		}),
		it("Should reorder items after Set", delegate() {
			auto cache = LRUEvictionQueue!string(4);
			cache.max_length.shouldEqual(4);

			// Add 4 items
			cache["1"] = "Tim";
			cache["2"] = "Al";
			cache["3"] = "Heidi";
			cache["4"] = "Wilson";
			cache.length.shouldEqual(4);

			cache.set("3", "Lisa");

			// Make sure item 3 was moved to head
			cache.keys.shouldEqual(["3", "1", "2", "4"]);
		}),
		it("Should fire event on eviction", delegate() {
			auto cache = LRUEvictionQueue!string(2);
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
			auto cache = LRUEvictionQueue!string(3);
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
	);
}
