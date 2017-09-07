


int main() {
	import lru_eviction_queue;
	import std.stdio : stdout;

	// Create a queue that will hold recipes
	auto recipes = LRUEvictionQueue!(string, string)(6);

	// Fire this event when an recipes is removed
	recipes.on_evict_cb = delegate(key, value) {
		stdout.writefln("Removed least used recipe to make room: %s\n", key);
	};

	// Add recipes
	stdout.writefln("Creating recipes ...\n");
	recipes["Spaghetti"] = "Pasta with tomato sauce";
	recipes["Sloppy joes"] = "Ground beef tomato sauce and onion sandwich";
	recipes["Burrito"] = "Chicken and cheese wrapped in a flour tortilla";
	recipes["Energy drink"] = "Banana protein powder with spinach blended in milk";
	recipes["Pot roast"] = "Beef slow roasted with carrots, onions, and potatoes";
	recipes["Pizza"] = "Flat bread toped with tomato sauce, cheese, and pepperoni";

	// Make a Burrito
	stdout.writefln("Making Burrito ...");
	stdout.writefln("    Description: %s\n", recipes["Burrito"]);

	// Make a Pizza
	stdout.writefln("Making Pizza ...");
	stdout.writefln("    Description: %s\n", recipes["Pizza"]);

	// Add BLT
	stdout.writefln("Adding BLT ...");
	recipes["BLT"] = "Bacon lettuce and tomato on white bread";
	stdout.writefln("Making BLT ...");
	stdout.writefln("    Description: %s\n", recipes["BLT"]);

	// Print the most and least recent recipes
	stdout.writefln("The most recent recipe is: %s\n", recipes.keys[0]);
	stdout.writefln("The least recent recipe is: %s\n", recipes.keys[$-1]);

	// Prints all the recipes
	stdout.writefln("recipes : %s", recipes.keys);

	return 0;
}
