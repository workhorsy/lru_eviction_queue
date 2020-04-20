// Copyright (c) 2017-2020 Matthew Brennan Jones <matthew.brennan.jones@gmail.com>
// Boost Software License - Version 1.0
// A LRU Eviction Queue for the D programming language
// https://github.com/workhorsy/lru_eviction_queue

/++
A LRU Eviction Queue for the D programming language

Home page:
$(LINK https://github.com/workhorsy/lru_eviction_queue)

Version: 1.7.0

License:
Boost Software License - Version 1.0

Examples:
----
import lru_eviction_queue;
import std.stdio : stdout;

// Create a queue that will hold 3 items
auto cache = LRUEvictionQueue!(string, int)(3);

// Fire this event when an item is evicted
cache.on_evict_cb = delegate(string key, ref int value) {
	stdout.writefln("Evicted item: %s", key);
};

// Fire this event when an item is updated
cache.on_update_cb = delegate(string key, ref int value) {
	stdout.writefln("Updated item: %s", key);
};

// Add
cache["aaa"] = 65;
cache["bbb"] = 97;
cache["ccc"] = 15;
cache["ddd"] = 46;

// Check that the key "aaa" was removed
if (! cache.hasKey("aaa")) {
	stdout.writefln("Item \"aaa\" was evicted!");
}

// Check that the key "ccc" was found
if ("ccc" in cache) {
	stdout.writefln("Item \"ccc\" was found!");
}

// Prints all the items in the cache
foreach (key, ref value ; cache) {
	stdout.writefln("%s : %s", key, value);
}
----
+/


struct LRUEvictionQueue(KEY, VALUE) {
	import std.container : SList;

	/++
	Creates a LRUEvictionQueue

	Params:
	 max_length = The max size of the queue. After this many items are added, the oldest items will be removed.

	Throws:
	 If max_length is less than 1, it will throw an Exception.
	+/
	this(size_t max_length) {
		// Make sure the args are valid
		if (max_length < 1) {
			throw new Exception("Cannot have a max_length less than 1.");
		}

		this._max_length = max_length;
		this._expiration_list = SList!KEY();
	}

	///
	unittest {
		auto cache = LRUEvictionQueue!(string, string)(100);
	}

	/++
	Returns true if a key is still on the queue

	Params:
	 key = The name of the key to check.
	+/
	bool hasKey(KEY key) {
		return (key in this._cache) != null;
	}

	///
	unittest {
		auto cache = LRUEvictionQueue!(string, string)(100);
		bool retval = cache.hasKey("name");
	}

	/++
	Sets the value in the queue. Will fire the on_evict_cb event if it is a new
	item that pushes an item off the queue. Will fire the on_update_cb event if
	updating an already existing key.

	Params:
	 key = The key to set.
	 value = The value to set.
	+/
	void set(KEY key, VALUE value) {
		// If the key is already used, update the value
		if (key in this._cache) {
			this.moveElementToFront(key);

			if (on_update_cb) {
				on_update_cb(key, this._cache[key]);
			}

			this._cache[key] = value;

			return;
		}

		// If the size will be greater than the max, remove the oldest element
		if (this._cache.length + 1 > this._max_length) {
			this.evictBackElement();
		}

		// If the key is new, add the new entry
		this._expiration_list.stableInsertFront(key);
		this._cache[key] = value;
	}

	///
	unittest {
		auto cache = LRUEvictionQueue!(string, string)(100);
		cache.set("name", "Bob");
	}

	/++
	Gets the value in the queue

	Params:
	 key = The key to get.
	 default_value = The value returned if the key is not found.
	+/
	VALUE get(KEY key, VALUE default_value) {
		// If it has the key, return the value
		if (key in this._cache) {
			this.moveElementToFront(key);

			return this._cache[key];
		}

		return default_value;
	}

	///
	unittest {
		auto cache = LRUEvictionQueue!(string, string)(100);
		string name = cache.get("name", string.init);
	}

	/++
	Removes the key from the queue. Does nothing if the key is not in the queue.
	 Will not fire any events.

	Params:
	 key = The key to remove.
	+/
	void remove(KEY key) {
		if (key in this._cache) {
			this.removeElement(key);
		}
	}

	///
	unittest {
		auto cache = LRUEvictionQueue!(string, string)(100);
		cache["name"] = "Alice";
		cache.remove("name");
	}

	/++
	Removes all the items from the queue. Will not fire any events.
	+/
	void clear() {
		this._expiration_list.clear();
		this._cache.clear();
	}

	///
	unittest {
		auto cache = LRUEvictionQueue!(string, string)(100);
		cache["name"] = "Tim";
		cache.clear();
	}

	/++
	Returns the length of the queue.
	+/
	size_t length() {
		return this._cache.length;
	}

	///
	unittest {
		auto cache = LRUEvictionQueue!(string, string)(100);
		cache["name"] = "Alice";
		size_t len = cache.length;
	}

	/++
	Returns the max length of the queue before items are removed.
	+/
	size_t max_length() {
		return this._max_length;
	}

	///
	unittest {
		auto cache = LRUEvictionQueue!(string, string)(100);
		size_t max_len = cache.max_length;
	}

	/++
	Returns all the keys in the queue.
	+/
	KEY[] keys() {
		import std.array : array;
		return array(this._expiration_list);
	}

	///
	unittest {
		auto cache = LRUEvictionQueue!(string, int)(100);
		cache["bbb"] = 5;
		cache["zzz"] = 7;
		string[] keys = cache.keys();
	}

	/++
	Used to iterate over the queue.
	+/
	int opApply(scope int delegate(ref KEY key, ref VALUE value) dg) {
		int result = 0;

		foreach (key ; _expiration_list[]) {
			result = dg(key, _cache[key]);
			if (result)
				break;
		}
		return result;
	}

	///
	unittest {
		auto cache = LRUEvictionQueue!(string, int)(100);
		cache["bbb"] = 5;
		cache["zzz"] = 7;
		foreach (key, ref value ; cache) {

		}
	}

	/++
	Gets the value in the queue. Throws if the key is not found.

	Params:
	 key = The key to get.

	 Throws:
 	 If the key is not found, it will throw an Exception.
	+/
	VALUE opIndex(KEY key) {
		import std.string : format;

		VALUE retval = this.get(key, VALUE.init);
		if (retval !is VALUE.init) {
			return retval;
		}

		throw new Exception("Invalid index '%s'.".format(key));
	}

	///
	unittest {
		auto cache = LRUEvictionQueue!(string, string)(100);
		cache["name"] = "Frank";
		string name = cache["name"];
	}

	/++
	Sets the value in the queue. Will fire the on_evict_cb event if it is a new
	item that pushes an item off the queue. Will fire the on_update_cb event if
	updating an already existing key.

	Params:
	 key = The key to set.
	 value = The value to set.
	+/
	VALUE opIndexAssign(VALUE value, KEY key) {
		this.set(key, value);
		return value;
	}

	///
	unittest {
		auto cache = LRUEvictionQueue!(string, string)(100);
		cache["name"] = "Lisa";
	}

	/++
	Returns a pointer to the value in the queue, or null.

	Params:
	 rhs = The name of the key to check.
	+/
	VALUE* opBinary(string op)(KEY rhs) {
		static if (op == "in") return (rhs in this._cache);
		else static assert(0, "Operator " ~ op ~ " not implemented");
	}

	///
	unittest {
		auto cache = LRUEvictionQueue!(string, string)(100);
		cache["name"] = "Lisa";
		string* result = "name" in cache;
	}

	VALUE* opBinaryRight(string op)(KEY lhs) {
		static if (op == "in") return (lhs in this._cache);
		else static assert(0, "Operator " ~ op ~ " not implemented");
	}

	/++
	The event to fire when an existing key is evicted

	Params:
	 on_evict_cb = The callback to fire.
	+/
	void delegate(KEY key, ref VALUE value) on_evict_cb;

	///
	unittest {
		auto cache = LRUEvictionQueue!(string, string)(2);
		cache.on_evict_cb = delegate(string key, ref string value) {

		};

		cache["aaa"] = "Lisa";
		cache["bbb"] = "Sally";
		cache["ccc"] = "Kevin";
	}

	/++
	The event to fire when an existing key is updated

	Params:
	 on_update_cb = The callback to fire.
	+/
	void delegate(KEY key, ref VALUE value) on_update_cb;

	///
	unittest {
		auto cache = LRUEvictionQueue!(string, string)(100);
		cache.on_update_cb = delegate(string key, ref string value) {

		};

		cache["name"] = "Lisa";
		cache["name"] = "Sally";
	}

	private void evictBackElement() {
		import std.range : tail;
		import std.array : array;

		auto r = tail(this._expiration_list[], 1);
		if (r.length > 0) {
			KEY key = array(r)[0];

			// Fire the on evict callback
			if (this.on_evict_cb) {
				this.on_evict_cb(key, this._cache[key]);
			}

			this.removeElement(key);
		}
	}

	private void moveElementToFront(KEY key) {
		import std.range : take;
		import std.algorithm : find;

		auto r = find(this._expiration_list[], key).take(1);
		this._expiration_list.stableLinearRemove(r);
		this._expiration_list.stableInsertFront(r);
	}

	private void removeElement(KEY key) {
		import std.range : take;
		import std.algorithm : find;

		// Remove the element from the expiration list
		auto r = find(this._expiration_list[], key).take(1);
		this._expiration_list.stableLinearRemove(r);

		// Remove the item from the cache
		this._cache.remove(key);
	}

	size_t _max_length;
	SList!KEY _expiration_list;
	VALUE[KEY] _cache;
}
