


int main() {
	import lru_eviction_queue;
	import std.stdio : stdout;

	// Create a queue that will hold items
	auto recipes = LRUEvictionQueue!(string, string)(6);

	// Fire this event when an item is evicted
	recipes.on_evict_cb = delegate(key, value) {
		stdout.writefln("Evicted item: %s %s", key, value);
	};

	// Add
	recipes["Spaghetti"] = "Pasta with tomato sauce";
	recipes["Sloppy joes"] = "Ground beef tomato sauce and onion sandwich";
	recipes["Burrito"] = "Chicken and cheese burritos";
	recipes["Energy drink"] = "Banana protein powder with spinach blended in milk";
	recipes["Pot roast"] = "Beef slow roasted with carrots, onions, and potatoes";
	recipes["Pizza"] = "Flat bread toped with tomato sauce, cheese, and pepperoni";

	// Prints all the items in the cache
	stdout.writefln("keys : %s", recipes.keys);
	
	//stdout.writefln("backpack : %s", cache);

	return 0;
}
