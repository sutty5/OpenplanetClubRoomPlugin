# Developing Trackmania 2020 Plugins with Openplanet (Windows & VSCode)

## Setting Up the Development Environment

Developing Trackmania 2020 plugins with Openplanet requires a proper Windows setup, including the Trackmania game (2020 edition) and the Openplanet modding platform. Follow these steps to prepare your environment:

1. **Install Trackmania (2020 via Steam):** Ensure Trackmania 2020 is installed on your PC via Steam (or Ubisoft Connect). Take note of the installation path (for Steam, the default is typically `C:\Program Files (x86)\Steam\steamapps\common\Trackmania`). You will need this path when installing Openplanet.

2. **Download and Install Openplanet:** Visit the Openplanet website’s download page for Trackmania and download the latest Openplanet installer (often named `OpenplanetNext_xxx.exe`). Run the installer and **select your Trackmania install folder** when prompted (the folder containing `Trackmania.exe`). The installer will integrate Openplanet with the game. By default, it suggests your Steam Trackmania directory – change it if your game is in a custom location. Complete the installation; Openplanet will place necessary files and create an **`OpenplanetNext`** directory in your user profile for plugin data.

3. **Launch Trackmania with Openplanet:** Start Trackmania normally (through Steam or Uplay). If Openplanet was installed correctly, it will inject its overlay into the game on launch. Press **F3** in-game to open the Openplanet overlay. A toolbar should appear at the top of the screen. This confirms Openplanet is active. (If the overlay doesn’t show, consult the Openplanet **Troubleshooting** guide to ensure any prerequisites like Visual C++ Redistributables are installed.)

4. **Verify Openplanet Overlay and Plugin Manager:** With the overlay open (F3), click the **“Openplanet”** menu on the left of the toolbar and select **“Plugin Manager”** (or find a Plugin Manager tab). The Plugin Manager dialog lets you browse and install existing plugins. This confirms that Openplanet is running correctly and you can proceed to development.

5. **Obtain Trackmania Club Access (if needed):** *Note:* Openplanet works on all editions of Trackmania, but some advanced features (including plugin development and certain APIs) require the **Club Edition** of the game. Club Edition unlocks the full Openplanet functionality, whereas Starter/Standard editions run Openplanet with limitations. For developing your own plugins, ensure your account has Club access (the subscription-based edition).

6. **Install Visual Studio Code:** Download and install **Visual Studio Code (VSCode)**, a popular code editor, if you haven’t already. VSCode will be used to write and organize your plugin scripts.

7. **Install the Openplanet Angelscript Extension:** Open VSCode and go to the Extensions view. Search for **“Openplanet Angelscript”** by *XertroV* and install it. This extension provides syntax highlighting, auto-completion, and a Language Server for the Openplanet-flavored AngelScript used in Trackmania. After installing, open the folder for your plugin (we will create this next) as a workspace in VSCode. **Important:** The extension expects you to open the **root folder of a plugin**, which must contain an `info.toml` file. We will set up this structure shortly. The extension will try to autodetect your Openplanet installation and game folder for API references; if it fails, you can configure the paths in the extension settings. Once configured, you should get auto-complete suggestions for Trackmania’s API classes and Openplanet functions within VSCode.

8. **(Optional) Remote Build Tooling:** For a smoother edit-test cycle, you can install the **Openplanet Remote Build** plugin (in-game) and a corresponding VSCode task extension. The Remote Build plugin (search “Remote Build” in the in-game plugin manager and install it) allows VSCode to instruct Openplanet to reload your plugin automatically. Additionally, the **“Openplanet Remote Build Tasks”** VSCode extension (by *skybaks*) adds tasks to compile and reload plugins via the Remote Build plugin. This is optional but can greatly speed up testing: instead of manually reloading the plugin in-game, you can press a hotkey or run a task in VSCode to push new script changes directly to the game.

With Trackmania, Openplanet, and VSCode set up, you are ready to create your first plugin. In summary, **install Openplanet into your Trackmania folder, verify the F3 overlay, and prepare VSCode with the AngelScript extension**. This environment will allow you to write, run, and debug custom plugins for Trackmania 2020.

## Plugin Project Structure and Architecture

Openplanet’s plugin system organizes each plugin as a self-contained folder with a specific structure. Understanding this structure and the plugin lifecycle is crucial before you start coding.

### Creating a Plugin Folder and Manifest

Each plugin lives in its own directory under the Openplanet plugins folder. By default, Openplanet uses a folder in your user profile for plugins (e.g. `C:\Users\<YourName>\OpenplanetNext\Plugins\`). To create a new plugin:

* **Make a New Plugin Folder:** Create a subdirectory under `OpenplanetNext\Plugins\` with your plugin’s name (for example, `MyFirstPlugin`). The folder name will be used as the plugin’s identifier and should be unique and descriptive.

* **Add an `info.toml` File:** Inside your plugin folder, create a text file named **`info.toml`**. This manifest file contains important metadata and settings for your plugin. The file uses the TOML format (plain text key-value pairs). At minimum, you should specify:

  ```toml
  name = "My First Plugin"
  author = "YourName"
  version = "1.0.0"
  description = "A hello world plugin for Openplanet."
  ```

  **Name** is the human-readable title of your plugin, **author** is your name or nickname, **version** is a semantic version string, and **description** is a short summary. These fields (and others) are used on the Openplanet website and in the plugin manager UI to identify your plugin. Every plugin **must have an `info.toml`** with at least these basic fields. (Legacy Openplanet plugins embedded metadata via preprocessor directives in the script, but the modern system uses `info.toml` for clarity.)

  Additional optional fields in `info.toml` include:

  * **game**: Specify game compatibility if needed (defaults to Trackmania Next for TM2020).
  * **dependencies**: A list of other plugins your plugin depends on (by their plugin ID or name). For example, to use the Nadeo Live Services API, you’ll depend on the `"NadeoServices"` plugin (more on this later).
  * **settings** or **permissions**: Some advanced plugins specify required permissions (like network access) or define user settings here. Most basic plugins can ignore this.

  The full list of `info.toml` options is available in the Openplanet documentation, but the above fields will get you started. Once `info.toml` is in place, VSCode should recognize the folder as an Openplanet plugin (if using the extension), and Openplanet (in-game) will be able to detect and load this plugin in development mode.

### Organizing Script Files

Openplanet plugins are scripted in **AngelScript** (*.as files*). You can have one or multiple `.as` files in your plugin folder – Openplanet will load and compile **all AngelScript files in the plugin folder** together at runtime. The file names do not particularly matter to Openplanet’s loading process; they exist to help you organize code. A common setup is to have a main script file (e.g. `Main.as`) and perhaps additional files for separate features or utility classes. All scripts in the plugin share the same global scope (they are compiled as one module), so they can call functions or use variables defined in each other without special import statements. Just be careful to avoid duplicate definitions. If needed, you can use AngelScript `namespace` blocks to prevent name collisions in large projects.

**Plugin Entry Point:** Openplanet looks for a special function in your scripts as the entry point, `void Main()`. Every plugin should define a `Main()` function; this is where execution begins when the plugin is loaded. You can think of it like a `main()` in C++ – Openplanet will call your `Main()` once to start the plugin.

**Example – `Main.as`:** Create a file (say `Main.as`) in your plugin folder with the following minimal code:

```cpp
// Main.as
void Main() {
    print("Hello from MyFirstPlugin!");  // Log a message to Openplanet console
}
```

This simple plugin, when loaded, will immediately print a greeting to the Openplanet log. The `print` function is provided by Openplanet’s API to output text to the in-game console/log window. We will discuss logging and other API functions in detail later. For now, note that `Main` has no arguments and returns nothing.

After writing `info.toml` and a `Main()` function as above, your plugin is essentially ready to be loaded in-game. During development, **Openplanet does not load custom plugins automatically on game start** (for security, only approved plugins are auto-loaded). Instead, you will load or reload your plugin manually for testing:

* Launch Trackmania and open the Openplanet overlay (F3). You should see a menu (likely labeled **“Scripts”** or **“Openplanet -> Development”**) that lists local plugins by name. Since you added `info.toml`, your plugin’s name (e.g. “My First Plugin”) should appear there. Click it to **load your plugin**. If everything is set up properly, you’ll see “Hello from MyFirstPlugin!” printed in the Openplanet console (you can view the console via **Openplanet -> Logs**). Congratulations – your plugin is running 🎉!

  *Tip:* During development, you can quickly reload a plugin after making changes. Either use the overlay menu (“Reload” option next to your plugin) or use the Remote Build tool discussed earlier to trigger reloads from VSCode. This avoids restarting the entire game each time you tweak your code.

### Plugin Lifecycle and Callbacks

Once loaded, a plugin can remain active until the user disables or unloads it (or until the game closes). Openplanet’s scripting environment is event-driven and also supports continuous scripts. Understanding the **plugin lifecycle** and available **callback functions** will help you structure your code effectively:

* **Main Function Execution:** When you load a plugin, Openplanet calls your `void Main()` function first. This is your plugin’s initialization point. Any code in `Main` will run once at plugin startup. If `Main()` finishes (returns), the plugin will actually stop running, and Openplanet will consider it “completed.” To keep a plugin running (for ongoing tasks or to respond to events over time), you typically do one of two things in `Main`: (a) run an infinite loop that periodically yields, or (b) simply return immediately and rely on callback functions (like `Render()` or `Update()`) for continuous behavior. Option (a) is common for scripts that need to perform background processing.

  **Yielding in Main:** Openplanet allows the `Main` function to be **“yieldable”**, meaning you can use `yield()` or `sleep(milliseconds)` within it to pause execution without returning. For example, you might have:

  ```cpp
  void Main() {
      while (true) {
          // ... do periodic work ...
          yield();  // pause until the next frame
      }
  }
  ```

  This structure keeps your plugin alive and running in a loop until the game exits or the plugin is unloaded. The `yield()` call hands control back to the game, preventing your loop from freezing the game. You can also use `sleep(ms)` to pause for a certain number of milliseconds. If you remove all yields and let `Main` run to completion, the plugin will end immediately after executing Main’s code. Thus, include a looping construct or event callbacks to keep it active.

* **Built-in Callback Functions:** Openplanet defines several special functions that, if present in your script, will be called automatically at appropriate times. You implement these only if you need them. The major callbacks include:

  | **Callback Function**                    | **When It’s Called**                                                                                                                                                                                                                                                                             |
  | ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
  | `void Render()`                          | Every frame, while in a map or menu. Use this to draw custom visuals each frame (e.g. 2D overlays). This is called during the game’s rendering loop, so keep it efficient.                                                                                                                       |
  | `void RenderInterface()`                 | Every frame, but intended for drawing UI elements in the Openplanet overlay or interface context. If your plugin creates ImGui-based UI windows (see UI API later), draw them here.                                                                                                              |
  | `void RenderMenu()`                      | Every frame when the Openplanet *menu* (overlay UI) is open. This is specifically for rendering within menu items in the overlay. Often not needed unless customizing the overlay itself.                                                                                                        |
  | `void Update(float dt)`                  | Every frame, for non-render logic updates. **dt** is the delta time (in seconds) since the last frame. Use this for time-based calculations or continuous state updates (e.g. physics or counters). For example, you might accumulate a timer using `dt` to trigger an action every few seconds. |
  | `void OnDisabled()` / `void OnEnabled()` | Called when the user disables or enables the plugin via the plugin manager. You can respond to these by freeing resources or resetting state. (These are optional; if not defined, nothing special happens on disable/enable beyond stopping callbacks.)                                         |
  | `void OnSettingsChanged()`               | If your plugin provides a settings interface (we won’t cover in detail here), this fires when the user changes a setting. It lets you apply new settings immediately.                                                                                                                            |

  You do **not** have to implement all (or any) of these – implement only what your plugin needs. For example, a simple logging plugin might use only `Main()` and `Update()` for logic, whereas a UI overlay plugin might use `RenderInterface()` for drawing UI each frame and not need an `Update`. If a callback is not present in your script, Openplanet just skips it. The *Main lifecycle* is worth reiterating: **Main runs once** on load, and if it contains a long-running loop or yields, it will effectively run in parallel with the above frame callbacks. If Main exits, your plugin will stop, so design accordingly.

* **Global State and Persistence:** Since AngelScript runs in a sandbox per plugin load, global variables in your script persist for the life of the plugin instance. You can keep state between frames in global or static variables (e.g. counting laps, toggling a feature). When the plugin is unloaded or the game closes, that state is lost (unless you save it to a file or setting). Openplanet also provides a way to store persistent settings (accessible via the Openplanet Settings UI) for your plugin – we’ll touch on that later in best practices.

* **Plugin Unloading:** If the user manually unloads or disables your plugin (or quits the game), any running `Main` loop or further callbacks will stop. It’s good practice to clean up in `OnDisabled` if you have things like open file handles or running coroutines, but usually simply breaking out of loops is sufficient. Openplanet handles freeing script objects and memory when the plugin unloads. If you need to explicitly remove drawn elements or listeners, do so in OnDisabled.

In summary, a typical plugin might use `Main()` for setup (and possibly a loop), `Update()` for continuous logic, and `Render()`/`RenderInterface()` for drawings or UI. The plugin architecture is flexible – you can write purely event-driven code (e.g. reacting to in-game events or user input) or run your own loops. Next, we will dive into the AngelScript language used for writing these scripts.

## AngelScript Language Overview (for Openplanet)

Openplanet uses **AngelScript** as its scripting language for plugins. AngelScript is a C++-like, statically-typed scripting language that is easy to learn if you have C, C++ or Java experience. This section provides a crash course in AngelScript syntax and features, as well as Openplanet-specific tips, so you can comfortably write plugin code.

### Language Characteristics and Syntax

**C++-like Syntax:** AngelScript’s syntax and semantics are very close to C++ (and by extension, C# or Java). You write statements ending in semicolons, use `//` for single-line comments and `/* ... */` for block comments, and define variables with types first. For example:

```cpp
int count = 0;
string playerName = "Unknown";  // string is a built-in class for text
bool isActive = true;
```

AngelScript supports standard primitives (`int`, `float`, `bool`, etc.), and also object types (classes). Openplanet exposes many game-specific classes (like `CGameCtnApp`, `CGamePlayerInfo`, etc.) which you will use frequently – more on those in the API section.

**Functions:** Defining functions looks similar to C++:

```cpp
int Add(int a, int b) {
    return a + b;
}
```

You can overload functions, use default parameters, etc., as needed. There is no need for a `main()` function to start the script (Openplanet uses `void Main()` as discussed above).

**Classes and Structs:** You can define your own classes or struct-like types in AngelScript if needed. For example:

```cpp
class MyData {
    int value;
    MyData(int v) { value = v; }
    void Increment() { value += 1; }
}
```

This is useful for organizing code, but many simple plugins might not need custom classes – they can work with the classes provided by the Trackmania API.

**Arrays and Containers:** Dynamic arrays are supported via the template type `array<T>` (provided by AngelScript’s standard library). Example:

```cpp
array<string> messages;
messages.InsertLast("hello");
print(messages[0]);  // prints "hello"
```

Openplanet also enables the AngelScript **dictionary** type (a key-value map) for convenience in plugins. You can use it as:

```cpp
dictionary playerStats;
playerStats["wins"] = 5;
int wins;
playerStats.Get("wins", wins);
```

This can be handy for caching data by key. (Under the hood, `dictionary` is part of AngelScript’s add-ons that Openplanet includes).

**Syntax Features:** AngelScript supports most common C++ constructs: `if/else` statements, `for`, `while` and `do` loops, `switch` statements, etc. It has bitwise operators, logical operators, and so on. A few differences to note:

* There is no concept of pointers or direct memory address manipulation in AngelScript; instead, you use **object handles** (similar to references) for objects.
* The language uses `@` to denote a handle (reference) to an object. This is extremely important when dealing with game objects from the Trackmania API. For example, `CGameCtnApp@ app = GetApp();` means `app` is a handle referring to the game application object. You can think of `@` like a pointer symbol that ensures proper reference counting. When you assign or pass object handles, the reference count is adjusted automatically, so the memory management is handled for you (no manual delete calls).
* Use `@` when you want to hold a reference to an object. If you use the object type without `@`, you are working with a copy or value type (for game classes, you almost always use handles). For instance: `CGamePlayerInfo@ pInfo = app.LocalPlayerInfo;` gives you a handle to the local player info object. If you accidentally do `CGamePlayerInfo pInfo = app.LocalPlayerInfo;` (without `@`), the script will try to make a copy, which usually isn’t allowed for these objects and will result in a compile error or unintended behavior.

**Memory Management:** AngelScript employs automatic memory management for objects. When you use object handles (`@`), the AngelScript engine uses reference counting to free objects when no references remain. You generally don’t worry about deleting objects – if you create a new object (e.g. `auto myObj = MyClass();` without an `@` means a stack object, with `@` means allocated on the heap and handled by refcount), just assign it to a handle and let the engine manage it. Cyclic references can be an issue (just as with any refcount system), but those are rare in typical plugin scenarios. If needed, you can use the `dictionary` or other structures to store data without leaking memory; just clear them or let the plugin unload to reclaim memory.

**Strings:** The `string` type in Openplanet’s AngelScript is akin to `std::string` in C++ or `String` in other languages. You can concatenate with `+`, compare, etc. **Note:** Trackmania’s engine often uses wide strings (Unicode) for player names, etc. In the API, you’ll see `wstring` used for names to support special characters. You can usually convert or assign a `wstring` to a normal `string` in AngelScript (Openplanet provides conversions). For example, if `playerInfo.Name` is a `wstring`, doing `string name = playerInfo.Name;` should give you a UTF-8 string. Keep in mind that special color codes (like `$<color>` codes in player names) might be present – those are part of Trackmania’s formatting.

**Best Practices & Tips:**

* **Use Descriptive Names:** Since all your plugin’s scripts share a global namespace (unless you explicitly use `namespace`), name your global variables and functions descriptively or prefix them (e.g., `g_playerCount`) to avoid collisions.
* **Immutability and Constants:** AngelScript supports `const` for variables and object handles. Use `const` where appropriate (e.g. `const float PI = 3.14159;`) to prevent accidental changes.
* **Error Handling:** AngelScript doesn’t have exceptions like C++. It typically uses return codes or simply fails script compilation on errors. If your code tries something invalid (like accessing a null handle), it may throw a runtime error and stop your plugin. To handle conditions, you’ll use checks (e.g., `if (obj is null) { /* ... */ }` for null handle checks). Openplanet will catch runtime script errors and report them in the log, but it’s up to you to avoid them or handle gracefully by checking pointers and conditions.
* **Comments and Documentation:** Comment your code for your own sanity. There is no built-in generation of documentation in AngelScript, but clear comments and consistent formatting will help when your plugin grows in size.

Next, let’s explore the Openplanet **API** – the set of objects and functions you can use to interact with Trackmania and the Openplanet platform. This is where you’ll see AngelScript in action with actual game data.

## Openplanet API Reference for Trackmania 2020

Openplanet exposes a rich API that allows your AngelScript plugin to interact with the Trackmania game engine and also utilize Openplanet’s own features. The API can be grouped into a few categories:

* **Game Engine Classes (Trackmania ManiaPlanet API)** – These are objects and functions that let you read and manipulate game state (players, maps, scores, etc.), essentially wrapping Trackmania’s internal classes. Openplanet’s documentation refers to this as the *Trackmania Next API*, since Trackmania 2020 is built on the ManiaPlanet engine.
* **Openplanet Utility API** – Additional functions and systems provided by Openplanet itself (not part of the base game). This includes things like the overlay UI system (ImGui-based), drawing utilities (NanoVG), file I/O, networking (HTTP requests), etc.
* **Web Services API** – Functions to interact with Nadeo’s online services (for example, retrieving player stats or leaderboard info via Trackmania’s web API). These are made available through a special dependency plugin (NadeoServices).
* **Plugin Management API** – Functions related to the plugin environment itself (for instance, accessing plugin settings, or inter-plugin communication via dependencies).

Below, we provide an overview of the most important APIs in each category, along with their usage, parameters, and any limitations. (For exhaustive details, refer to the official Openplanet documentation online – it lists every class and member, but here we will summarize the essentials.)

### Game Engine Classes and Trackmania-Specific API

Trackmania (2020) shares many engine classes with previous ManiaPlanet-based games, and Openplanet makes these available to scripts. The root of most game interactions is the **application object**, which you obtain via the global function `GetApp()`:

* **`CGameCtnApp@ GetApp()`** – Returns a handle to the main Trackmania application object. In Trackmania 2020, the actual object type is `CTrackMania` (a subclass of `CGameCtnApp`), but you can use it through the base class or cast to `CTrackMania` if needed. This object is your entry point to many game subsystems.

Using the app object, you can access numerous properties and sub-objects. Some key fields and their use:

| **Property/Field**      | **Description & Usage**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `app.CurrentPlayground` | A handle to the current active **playground** (game session). This represents the race or menu that is currently active. If the player is in a map (solo or online), `CurrentPlayground` is a `CGamePlayground` object with info about that session. If `null`, no map is currently running (e.g., user is at main menu). From the Playground, you can get players, game results, etc. *Note:* Accessing some subfields might require the game to be in a certain state; always check for `null` before use. |
| `app.RootMap`           | A handle to the **currently loaded map** (as a `CGameCtnChallenge` object). This is typically valid when you are in the map editor or have a map loaded for play. It contains properties like the map name, author, etc. In a live race, you might prefer to get map info via the Playground’s script API, but `RootMap` is handy in the editor or when a map is loaded but not yet started.                                                                                                                 |
| `app.LocalPlayerInfo`   | A `CGamePlayerInfo` object for the local player profile. This includes details such as the player’s **Login** (unique account name) and **Name** (display name) among other stats. For example, `string login = app.LocalPlayerInfo.Login;` gives your account login; `wstring playerName = app.LocalPlayerInfo.Name;` gives your in-game name (with formatting codes).                                                                                                                                      |
| `app.Network`           | A `CGameCtnNetwork` object representing the network manager. This can tell you if the player is connected to a server, provide server info, etc. If you are offline, many fields here will be null or default. If online, you can find data about the server or other players.                                                                                                                                                                                                                               |
| `app.PlaygroundScript`  | A `CGamePlaygroundScript` interface. This is an interface to the ManiaScript of the current playground. It can provide certain high-level scripted info, but in Openplanet you often won’t directly use this unless you need very specific script-layer data. (Many plugins instead use the more direct data fields or the dedicated MLFeed data – see *Vehicle and Race Data* below).                                                                                                                       |
| *Inherited fields...*   | The app object inherits from base classes (`CGameManiaPlanet`, etc.), which include other fields not listed above. For example, `LoadedManiaTitle`, `MenuManager`, etc., which relate to the ManiaPlanet title system. In Trackmania’s context, these are less commonly used, as Trackmania 2020 always runs the Trackmania title.                                                                                                                                                                           |

Beyond the application object, there are classes for **players, vehicles, map objects, etc.** Here are a few important ones you might interact with:

* **Player and Vehicle:** In a racing context, the `CGamePlayground` will have a collection of player objects. Trackmania’s player class may appear as `CSmPlayer` (ShootMania player, since Trackmania uses a variant of that) or a `CTrackManiaPlayer`. The player object can link to a `CGameMobil` or specifically a `CGameVehicle` which has the physics state of the car (speed, position, etc.). Directly accessing the vehicle state can be complex (it’s updated frequently and some fields are not trivial), which is why Openplanet includes a helper **“VehicleState”** plugin to provide easy access to current speed, acceleration, etc., for your car. If you need those, you can depend on `VehicleState` rather than digging through the raw classes. For simpler data like player name or checkpoints, you can use the provided APIs or events.

* **Map and Blocks:** `CGameCtnChallenge` (often just called *Challenge* or *Map*) represents the track. It has information like the track name, environment, list of blocks placed, etc. You might use this in an editor plugin (for example, to count blocks or validate something about the map). Be cautious: some map editing operations might not reflect immediately in the `Challenge` object until saved.

* **Scores and Timing:** In an active race, `CGamePlayground` may contain a `CGamePlaygroundUI` or similar class that holds the timer, checkpoint times, etc. There’s also a ManiaScript interface for results. Tracking race times through the raw API can be tricky – many community plugins instead rely on the **MLFeed (ManiaLink Feed)** system that Openplanet provides for live data (via the `MLFeed` plugin by XertroV). MLFeed can push events like checkpoint crossings, finish times, etc., to your plugin. This is an advanced topic, but if you plan to make a rich gameplay mod (like ghost comparisons, live checkpoint counters), consider using these feeds or dependencies.

**Using the Game API – Example:** To tie this together, here’s a short example of using game classes. Suppose we want to display the player’s name and current map name on screen:

```cpp
string playerName = "Unknown";
string mapName = "No Map";
CGameCtnApp@ app = GetApp();                // Get the application
if (app !is null) {
    playerName = string(app.LocalPlayerInfo.Name);  // Convert wide string to string
    if (app.RootMap !is null) {
        mapName = app.RootMap.MapName;      // MapName property of CGameCtnChallenge
    }
}
print("Player: " + playerName + ", Map: " + mapName);
```

In this snippet, we used `GetApp()` to retrieve the app object. We then accessed `LocalPlayerInfo.Name` to get the player's name, and `RootMap.MapName` for the track name. We had to check for nulls – if no map is loaded, `RootMap` could be null. Also, `Name` is a `wstring` so we explicitly cast to `string` for printing. This printed info to the log; you could similarly draw it on-screen in a Render callback or UI (coming up in UI section).

**Limitations:** The game API allows **reading a lot of game state** and some level of controlled modification, but it does *not* allow outright cheats or unrestricted modifications. For example, you cannot use Openplanet to give your car unlimited speed or to directly change another player's time – such actions are not exposed to the scripting API. Openplanet deliberately omits or protects functions that would compromise fairness or game integrity. Additionally, some classes and methods might exist in the documentation but are marked as not usable or simply have no effect if called – those are typically remnants of the engine that aren’t relevant to Trackmania or are blocked for safety. When using any function that alters state (like maybe `Start()` on the app, or sending inputs), be cautious and test thoroughly. The documentation will often show if something is read-only (e.g., properties labeled `const` cannot be modified by script).

### Openplanet Utility APIs (UI, Drawing, I/O, etc.)

In addition to the game classes, Openplanet provides a variety of **utility namespaces** and functions to help you create interactive and informative plugins. These include user interface creation, rendering tools, file and network access, and more. Below we detail some of the most commonly used utilities with examples:

#### ImGui User Interface (UI Namespace)

Openplanet includes an embedded Dear **ImGui** system (Immediate Mode GUI) for plugins. This is exposed through the **`UI::`** namespace. It allows you to create custom windows, menus, buttons, sliders, text inputs – virtually any UI element – that appear in the Openplanet overlay. These UI elements are drawn only when the Openplanet overlay is open (F3 toggled) or if you specifically create a persistent overlay window.

Key functions and usage from the `UI` namespace:

* **Creating a Window:** Use `UI::Begin("Window Title", flags)` and `UI::End()` to create a window. For example:

  ```cpp
  void RenderInterface() {
      UI::SetNextWindowSize(300, 100, UI::Cond::Appearing);
      if (UI::Begin("My Plugin Window", UI::WindowFlags::NoCollapse)) {
          UI::Text("Hello, " + playerName);
          if (UI::Button("Press Me")) {
              OnButtonPressed();
          }
      }
      UI::End();
  }
  ```

  In this snippet, `RenderInterface()` is called each frame for the UI (because we want to draw an ImGui window). We set an initial window size, then open a window named "My Plugin Window". Inside, we draw some text and a button. If the button is clicked, we call some function. The `UI::WindowFlags` and `UI::Cond` are enums provided to control window behavior (e.g., `NoCollapse` means the window cannot be collapsed).

* **Simple Widgets:** `UI::Text("text")` draws text. `UI::Button("label")` draws a button and returns true when clicked. Other widgets include `UI::InputText("label", variable)`, `UI::SliderInt("label", value, min, max)`, `UI::Checkbox("label", boolVar)`, etc. These mirror the ImGui library’s functions. For icons or special formatting, Openplanet provides an `Icons::` font (common Trackmania icons accessible via codes) and supports basic formatting tags.

* **Menu Integration:** If your plugin should add an item to the Openplanet top menu (for example, some plugins add their own dropdown in the menu bar), you can use the `UI::MenuItem` and related functions in a special way. However, a simpler approach: Many plugins simply create a togglable window that the user can open via a chat command or a key bind. The UI system doesn’t automatically add your window to the main menu; you’d either instruct users to toggle the overlay and find your window, or implement a small mechanism (like a key press detection) to open/close your window.

* **Condition for Drawing:** The `RenderInterface()` callback is ideal for UI. If you draw in `Render()` (which is also every frame but meant for 3D world overlay), ImGui may not function correctly or will be drawn off-screen. Use `RenderInterface()` for all ImGui windows and UI widgets to ensure they overlay properly on the game’s interface layer.

**Limitations:** ImGui windows drawn by plugins will only show up when the Openplanet overlay is active (unless you use `UI::SetNextWindowOverlay(...)` to deliberately make an overlay that appears even when the main menu is hidden – advanced use). Generally, consider UI as a supplement for configuration or information display, not something that should always cover the game without user toggling the overlay. Also, avoid creating too many windows or heavy UI updates per frame, which could impact performance.

#### 2D Drawing (NanoVG – `nvg` Namespace)

For plugins that need custom drawing (graphs, shapes, lines, HUD elements, etc.) outside of the standard UI widgets, Openplanet provides the **NanoVG** vector graphics library. The `nvg::` namespace lets you draw shapes, text, and images in a 2D context over the game view.

Key capabilities of `nvg`:

* Draw shapes like rectangles, circles, lines, paths with customizable fill and stroke.
* Draw text with specified font size and color.
* It's great for HUD overlays (e.g., drawing a custom speedometer arc, or highlighting parts of the screen).

Example usage:

```cpp
void Render() {
    // Draw a semi-transparent red rectangle on screen
    nvg::BeginPath();
    nvg::Rect(100, 100, 300, 150);
    nvg::FillColor(vec4(1, 0, 0, 0.5));  // RGBA (0.5 alpha for transparency)
    nvg::Fill();
    nvg::ClosePath();
}
```

This would draw a red rectangle at (100,100) pixels. The coordinate system is pixel-based with (0,0) at the top-left of the screen (for the overlay context). You can get screen dimensions via `Draw::GetWidth()` / `GetHeight()` if needed.

For text:

```cpp
nvg::FontFace("$Futura");  // Using an in-game font (Openplanet provides some)
nvg::FontSize(36);
nvg::FillColor(vec4(1,1,1,1));
nvg::Text(200, 200, "Speed: " + Text::Format("%.1f", currentSpeed));
```

Openplanet has some built-in fonts (like `$Futura` and others corresponding to game fonts). The `Text::Format` used above is another utility (in `Text::` namespace) similar to `sprintf` for formatting strings.

**Choosing UI vs nvg:** If you need interactive elements (buttons, sliders), use UI (ImGui). If you need purely drawing some visual element each frame (like a custom gauge or effect), `nvg` is the way to go. You can combine them (e.g., a plugin that has an ImGui window with settings but also does `nvg` drawing in the game world).

**Limitations:** NanoVG drawing occurs in the world overlay context (`Render()` callback). If the user disables the overlay (F3), your `Render()` drawings will *still appear* over the game (unlike UI windows which disappear). This is useful for HUDs that should always be visible during gameplay. However, be mindful: drawing too many things or complex paths every frame can reduce performance. Keep shapes simple or precompute as much as possible. Additionally, you cannot use NanoVG to draw *underneath* the game’s 3D world – it’s always an overlay on top of the scene.

#### File I/O and Persistence (IO Namespace)

Plugins often need to read or save data (configuration, logs, cached records, etc.). Openplanet allows controlled file system access through the **`IO::`** namespace. Plugins are typically sandboxed to specific directories for security. Notably:

* **Storage Folder:** Each plugin has a storage location under the Openplanet directory. You can get a path to a file in your plugin’s folder using `IO::FromStorageFolder("filename")` which returns a string path. This ensures you read/write in your plugin’s own folder.

* **Reading & Writing Files:** Use `IO::File`. Example:

  ```cpp
  IO::File file("output.txt", IO::FileMode::Write);  // open file for writing (overwrites)
  if (file.CanWrite()) {
      file.WriteLine("Hello File!");
      file.Close();
  }
  ```

  Here we create (or truncate) *output.txt* in the plugin’s storage directory and write a line. Always check `CanWrite()` or `CanRead()` after opening. The `IO::FileMode` enum has options: Read, Write, Append, etc. There are corresponding `ReadLine()`, `WriteLine()`, `ReadToEnd()`, etc., for convenience.

* **Listing Files:** You can list files in a directory via `IO::IndexFolder(path, recursive)` which returns an array of file/folder names. Useful if your plugin stores multiple files (e.g., map caches).

* **Paths:** `IO::FromStorageFolder("file")` gives `"<UserProfile>\\OpenplanetNext\\Plugins\\MyFirstPlugin\\file"`. If you need the game’s folder, use `IO::FromAppFolder("file")` to get a path in the Trackmania install directory (useful if you need to read game files, but writing there may not be allowed). There’s also a `IO::SpecialFolder` enum if needed (for Documents, etc., but typically not needed).

**Limitations and Permissions:** By default, plugins can read/write in their own plugin folder (and perhaps certain shared areas) but **cannot write arbitrarily anywhere on disk for security**. Openplanet might block access outside allowed directories. This is usually fine, as using `IO::FromStorageFolder` ensures you stay in the safe zone. If your plugin needs to generate substantial data, be mindful of size – extremely large writes could be slow or fill the user’s disk. Always close files when done to flush data.

#### Network Requests (Net Namespace)

Openplanet provides the `Net` namespace to perform HTTP requests, allowing your plugin to communicate with web services or APIs. This can be powerful – for example, fetching data from a community API like Trackmania.io or posting results to a server. Common functions:

* **`Net::HttpGet(url)`** – Performs a GET request to the specified URL and returns a `Net::HttpRequest` object which you can poll for completion. For example:

  ```cpp
  auto req = Net::HttpGet("https://api.trackmania.com/some/endpoint");
  while(!req.Finished()) {
      yield();  // wait for the request to finish
  }
  if(req.Success()) {
      string response = req.String();
      // parse JSON or do something
  }
  ```

  You typically yield until `req.Finished()` is true (so as not to block the game). You can also set a callback for when it finishes instead of looping.

* **`Net::HttpPost(url, content)`** – Similar, but sends a POST with given content (and you can specify content type, etc.).

There are also more advanced usage like adding headers (e.g., for authentication) via `Net::HttpRequest@ req = Net::Request(...)` and then `req.Start()` after adding headers.

**Nadeo Live Services (Authentication):** A special note – if you want to call Nadeo’s official Trackmania web services (which require an authentication token tied to the player, for example to get club info, upload ghosts, etc.), you should use the **NadeoServices plugin** that comes with Openplanet. Instead of manually doing an OAuth flow, you simply declare a dependency on `NadeoServices` in your info.toml and call:

```cpp
NadeoServices::AddAudience("NadeoLiveServices");  // request a token for official API
while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) {
    yield();  // wait for Openplanet to get the token
}
string token = NadeoServices::GetToken("NadeoLiveServices");
// Now you can use this token in Authorization header for your Net requests to Nadeo API
```

Openplanet will automatically handle retrieving your authentication token (using your logged-in session) if you have the Club edition and have added the audience. This is much easier and safer than trying to manage login credentials yourself. Always use the provided NadeoServices functions for official APIs. Remember, you must list `"NadeoServices"` in your plugin’s `dependencies` for these functions to be available and for your plugin to require that the user has the dependency installed. Openplanet will ensure the NadeoServices plugin is present (and if not, prompt the user to install it) when they install your plugin.

**Example (Web Request):** Suppose your plugin needs to fetch a JSON config from a URL (maybe you host some configuration online). You could do:

```cpp
void FetchConfig() {
    auto req = Net::HttpGet("https://myserver.com/config.json");
    while(!req.Finished()) {
        yield();  // wait for request to complete
    }
    if(req.Success()) {
        string data = req.String();
        ParseConfigJson(data);
    } else {
        warn("Failed to fetch config, error code: " + req.ResponseCode());
    }
}
```

Openplanet’s `Net::HttpRequest` object offers properties like `req.ResponseCode()` for HTTP status, `req.String()` to get the body as string (or `req.Buffer()` for raw bytes), and `req.Success()` convenience which checks if status is 200 and no errors.

**Limitations:** Network calls are subject to the user’s connectivity and the remote server’s responsiveness. Always code defensively: check for success, handle timeouts (there’s a default timeout of \~10 seconds on requests). Also, Openplanet may restrict some networking if the user opts out (there is a setting to disable external requests globally for privacy). If your plugin heavily uses the network, inform the user (and possibly provide a setting to disable that feature). Large downloads should be approached carefully to not freeze the game – since we use `yield()`, the game stays responsive, but retrieving a huge `req.String()` could use a lot of memory. You might stream data in chunks if needed (Openplanet’s API allows some streaming reads, though that’s advanced).

### Summary of Key Openplanet APIs

To recap, here is a reference table of key APIs we discussed, for quick scanning:

| **API Class/Function**                            | **Description**                                                                                                                                                                                   | **Reference**                        |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ |
| `GetApp()`                                        | Returns main game app object (`CGameCtnApp@`). Use this to access game state (playground, player info, etc.).                                                                                     | Openplanet Global Function           |
| `CGameCtnApp` / `CTrackMania`                     | Application classes. Key fields: `CurrentPlayground`, `RootMap`, `LocalPlayerInfo`, etc. Methods to start/end game (rarely used in TM2020 context).                                               | Trackmania Game API                  |
| `CGamePlayground`                                 | Represents a running session (race). Contains players, scores, events. Often accessed via app.CurrentPlayground.                                                                                  | Trackmania Game API                  |
| `CGamePlayerInfo`                                 | Player profile info (login, name, etc.) for local or other players. Mostly read-only.                                                                                                             | Trackmania Game API                  |
| `UI::Begin()/End()`                               | Create an ImGui window in overlay. Used in `RenderInterface()`.                                                                                                                                   | Openplanet UI API                    |
| `UI::Text(), UI::Button(), UI::Slider...`         | Draw UI widgets inside a window. Handle user input (button clicks, etc.).                                                                                                                         | Openplanet UI API                    |
| `nvg::BeginPath()/Fill()`                         | Draw 2D shapes (rectangles, circles, lines) on screen in `Render()`. Useful for custom HUD elements.                                                                                              | Openplanet NanoVG API                |
| `nvg::Text()`                                     | Draw text with NanoVG. Requires setting font and fill color first.                                                                                                                                | Openplanet NanoVG API                |
| `IO::File(file, mode)`                            | Open or create a file in plugin storage. Allows reading/writing text or binary.                                                                                                                   | Openplanet IO API                    |
| `IO::FromStorageFolder(f)`                        | Get full path for a file in plugin’s folder. Useful to construct paths for `IO::File`.                                                                                                            | Openplanet IO API                    |
| `Net::HttpGet(url)`                               | Perform HTTP GET request. Returns a request object to monitor. Must yield until completion.                                                                                                       | Openplanet Net API                   |
| `Net::HttpRequest`                                | Object from HttpGet/Post with methods: `Finished()`, `Success()`, `String()`, `ResponseCode()`, etc.                                                                                              | Openplanet Net API                   |
| `NadeoServices::AddAudience("NadeoLiveServices")` | Request authentication for official Trackmania services (requires Club access). Use before calling Nadeo APIs.                                                                                    | Openplanet Web Services (dependency) |
| `NadeoServices::GetToken(audience)`               | Retrieve the auth token after adding audience and authentication. Use this token in `Net` requests to official API.                                                                               | Openplanet Web Services (dependency) |
| `Meta::GetPluginSettings(pluginID)` (advanced)    | Access another plugin’s settings or data if exposed. (Advanced usage for inter-plugin communication, requires knowing plugin ID and that plugin allowing it.)                                     | Openplanet Meta API                  |
| `trace`, `warn`, `error`                          | Logging functions. `print()` is basic logging; some contexts offer `trace()` (verbose log), `warn()` (warning log), `error()` (error log). These tag messages in the Openplanet log for severity. | Openplanet Logging                   |

The above covers many core APIs. There are more specialized ones (for example, **ManiaLink** related APIs if you want to create in-game ManiaLinks or XML dialogs, or hooking input events via a `VirtualKey` code) but those are beyond the scope of this intro. The **Openplanet documentation website** has a full listing of all classes and functions with their parameters and inheritance – it’s a great resource to find what’s available. Use the VSCode extension’s autocomplete and hover documentation as well; it can show you function signatures and brief docs for many API calls as you type.

### Building, Testing, and Debugging Plugins

Now that you can write a plugin, how do you **build** (compile) and test it? The good news: there is no separate “build” process like compiling C++ – Openplanet JIT-compiles your AngelScript code on the fly. The cycle is basically *edit → load → test → repeat*. Here are best practices for building and debugging:

* **Saving and Reloading:** Simply saving your `.as` files and then reloading the plugin in-game will compile the new code. If there are compile errors, Openplanet will show them in the log (with file name and line number). You can view these errors in the Openplanet overlay under Logs. The VSCode extension also listens for these errors via the Remote Build plugin: if you use the remote build task to reload, it will capture compile errors and display them in VSCode, highlighting the lines, which is very convenient.

* **Handling Compile Errors:** If your code doesn’t compile, no part of it runs. Fix the error (the error messages are usually clear, like “no matching function call for ...” or “unexpected token”). Common mistakes are missing semicolons, using `@` incorrectly, or wrong variable types. Use the error line info and consult documentation if needed.

* **Runtime Errors and Debugging:** If your plugin compiles but something isn’t working right, you can use logging to debug. The simplest is `print("value: " + value);` to trace execution. For more structured logging, you can use `warn()` to highlight potential issues (these show up in yellow in the log) or `error()` for serious problems. For example:

  ```cpp
  if (app.CurrentPlayground is null) {
      warn("No playground active, skipping update.");
  }
  ```

  This helps you see what code paths are hit. The log is persistent while the game runs, and saved to a file (`OpenplanetNext/Logs/` directory) which you can inspect after if needed.

* **Stepping Through Code:** There is currently *no step debugger* for Openplanet scripts (no breakpoints or line-by-line execution in VSCode). Therefore, logging and careful reasoning are your main tools. You can also simulate some logic outside the game by writing small test functions and verifying their output in logs.

* **Crash Safety:** A buggy plugin typically won’t crash the whole game – Openplanet runs plugins in a sandbox. If your script does something illegal (null pointer access, division by zero, etc.), Openplanet will throw a runtime exception and halt your plugin (and log the error). The game should continue running. You can then fix the issue and reload the plugin. In rare cases, certain calls might freeze the game (for example, a poorly written infinite loop with no yields will hang the render thread). If that happens, you might have to kill the game process. Just be mindful to always yield in long loops and don’t block the main thread.

* **Testing Iteratively:** Develop in small increments. For example, get `Main()` printing something first, then add an `Update()` and see if it runs, then add that complex logic. This way, when something breaks, you know it was the last change. Use version control (Git) to track changes – more on that in best practices.

* **Local Installation of Plugins:** During development, your plugin sits in the `OpenplanetNext\Plugins\MyPlugin` folder. It’s effectively “installed” locally (just not through the manager). If someone else wanted to try it before publishing, they could drop your plugin folder into their own `Plugins` directory. However, normally distribution is done via the Openplanet website (next section). For debugging on your own, feel free to leave the plugin in the folder. When you want to disable it, you can either uninstall via overlay or just move the folder out.

* **Using the Developer Menu:** Openplanet overlay has a **“Developer”** menu (sometimes called Scripts menu) which, when Developer Mode is enabled, shows additional tools. For example, you can reload the entire scripts engine, or load a specific plugin by folder name. Ensure Developer Mode is on (in Openplanet settings, there’s an option to show developer options). This is mostly already covered by what we’ve done (manually loading the plugin by name is part of that menu).

* **In-Game Tools:** There are some built-in plugins that help development. For instance, the "Logs" window shows real-time log output (useful to see your prints without tabbing out). There’s also a "Profiler" plugin that can measure your plugin’s performance (if you suspect it’s slowing the game). And as mentioned, the Remote Build plugin which syncs with VSCode tasks to auto-reload plugins.

### Preparing Plugins for Distribution

When your plugin is tested and ready to share, you should publish it on the Openplanet website so that others can download and install it easily (and so it gets digitally signed by the Openplanet system). The distribution process involves a few steps:

1. **Create an Openplanet Account:** Go to **openplanet.dev** and sign up or log in (the site may use ManiaExchange or Nadeo accounts – follow the instructions on the site). Having an account lets you submit plugins.

2. **Submit a New Plugin:** On the Openplanet site, go to the Plugins section and look for an option to **Upload Plugin**. You will be asked to provide the `info.toml` and script files. Usually, you will upload a `.zip` of your plugin folder (containing `info.toml` and all `.as` files, plus any assets your plugin needs). Make sure your `info.toml` is filled out with the final name, version, and description you want users to see. The website will parse this and display info accordingly.

3. **Plugin Review and Signing:** When you upload, the plugin is not immediately public. It goes into a review queue. The Openplanet team (or automated checks) will verify that the plugin is safe (no malicious code, not blatantly cheating, etc.). **Plugin signing is handled automatically by the website’s review system**. You don’t need to manually sign anything. Once approved, the system will attach a digital signature to your plugin, and it will be listed on the Openplanet plugin repository. This signature is what allows Openplanet in-game to trust and auto-load the plugin for users. (Unsigned plugins can only be loaded manually by users in dev mode, as we did during development.)

4. **Versioning:** Each time you update your plugin, you’ll upload a new version on the site. The `version` field in `info.toml` should be incremented (e.g., 1.0.0 -> 1.1.0) so that users get notified of an update. The site’s review process repeats for new versions but is usually quicker for small changes. Users can enable auto-update or will see an “Update” button in the plugin manager.

5. **Distribution Package:** The site might ask you to include a short changelog or additional images (like an icon or screenshots of your plugin) to display on the plugin page. Providing these can make your plugin page more attractive. You can also specify a homepage or source code URL if you want (encouraged if you open source your plugin on GitHub).

6. **After Publishing – Testing:** Once published, try installing your plugin via the in-game plugin manager (just as a user would) to double-check everything works from a clean install perspective. This can catch issues like forgetting to include a resource file in the uploaded package.

7. **Openplanet Guidelines:** Ensure your plugin adheres to any community guidelines. Generally: no hateful content, no cheating in multiplayer, no disruptive behavior. The review usually filters this. Also, avoid using others’ code without credit if publishing (respect licenses). You may include third-party AngelScript libraries if needed, but mention them.

The Openplanet site handles making your plugin accessible to all users. After approval, anyone can find it by name or browse categories. The next time they press F3 and open Plugin Manager, they can search your plugin and install it with one click. The manager downloads the package and places it in their `OpenplanetNext\Plugins` folder automatically.

**Signing and Security:** As mentioned, the signing process is automatic and mandatory. If you try to share your plugin by just giving someone the files, they can use it, but the game will label it as “Unverified” and it won’t auto-run on their system unless they explicitly allow local plugins. Publishing through the site is the way to reach a broad audience and have your plugin run seamlessly for others.

**Updates and Feedback:** Once out there, users might comment on your plugin’s page or on forums/Discord with feedback or bug reports. Be prepared to update accordingly. It’s good practice to version control your plugin (e.g., using GitHub) so you can track changes and allow others to possibly contribute if you open source it.

## Example Plugins and Code Samples

To solidify the concepts, let's walk through a few common types of plugins with simplified examples. These examples illustrate how to combine the API and AngelScript to achieve typical plugin functionality. (You can use these as starting points for your own projects!)

### Example 1: “Hello World” Logging Plugin

**Type:** Basic utility – Logs a message or periodically prints information to the Openplanet console.

This example simply demonstrates a plugin that stays active and prints a message every few seconds. It uses the `Main` loop and `sleep()` for timing.

```cpp
// info.toml (metadata)
/*
name = "HelloLogger"
author = "YourName"
version = "1.0.0"
description = "A simple plugin that logs a greeting every 5 seconds."
*/

// Main.as
void Main() {
    uint counter = 0;
    while(true) {
        counter++;
        print("Hello from Openplanet! Count = " + counter);
        sleep(5000); // sleep 5 seconds
    }
}
```

**What it does:** Upon loading, this plugin enters an infinite loop in `Main` and prints a message with an incrementing counter every 5 seconds. The `sleep(5000)` yields the script for 5000 ms (5 seconds) without blocking the game. You would see in the Openplanet Logs:

```
Hello from Openplanet! Count = 1
Hello from Openplanet! Count = 2
...
```

and so on, every five seconds. This example verifies that our environment is working and shows how to use basic timing.

**Key points:** We used `while(true)` with `sleep` – this keeps the plugin alive. We avoided doing this in `Update()` because using `sleep` in `Update()` isn’t possible (Update isn’t a coroutine), and a tight loop in Update would be called every frame (not what we want for a timed message). `Main` is ideal for such loops.

### Example 2: UI Overlay Plugin (Display Player Info)

**Type:** UI overlay – Creates a window in the Openplanet overlay showing some dynamic information (e.g., player name and current server or map).

We’ll make a plugin that opens a small window in the overlay. It demonstrates using the UI API and reading some game state each frame.

```cpp
// info.toml
/*
name = "PlayerInfoDisplay"
author = "YourName"
version = "1.0.0"
description = "Displays the local player name and current map name in a UI window."
*/

// Main.as (could also split UI code to another file if preferred)
bool showWindow = true;

void RenderInterface() {
    if (!showWindow) return;
    // Set window position or size if desired
    // UI::SetNextWindowPos(10, 10, UI::Cond::FirstUseEver);
    if (UI::Begin("Player Info", showWindow)) {  // Pass showWindow by reference to allow closing
        CGameCtnApp@ app = GetApp();
        if (app !is null) {
            string player = "Unknown";
            string map = "None";
            if (app.LocalPlayerInfo !is null) {
                player = string(app.LocalPlayerInfo.Name);
            }
            if (app.RootMap !is null) {
                map = app.RootMap.MapName;
            } else if (app.CurrentPlayground !is null) {
                // If in an online server or ongoing map, RootMap might be null, try playground map
                map = app.CurrentPlayground.Map.MapName;  // Map property inside playground
            }
            UI::Text("\\$ffdPlayer:\\$z " + player);
            UI::Text("\\$ffdMap:\\$z " + map);
        } else {
            UI::Text("Game not running.");
        }
        UI::Separator();
        if (UI::Button("Close")) {
            showWindow = false;
        }
    }
    UI::End();
}
```

**Explanation:** This plugin continuously draws a window titled "Player Info" (only when `showWindow` is true). Inside, it fetches the `app` object and extracts the local player’s name and current map name. We demonstrate a fallback: if `RootMap` is null (which can happen on a server before map start), we try to get map name via `app.CurrentPlayground.Map.MapName`. We display the info with some color formatting (`\$ffd` is a color code for golden yellow in Trackmania’s text formatting). The UI::Separator draws a line, and a "Close" button sets `showWindow` to false, which will stop drawing the window (until maybe we re-enable it by some other means – e.g., reloading plugin or adding a key toggle).

To test this, load the plugin, press F3 to open overlay, and you should see the "Player Info" window (it will appear automatically on first use). It should list your player name and either the map you’re playing or “None” if at menu. The text uses in-game coloring (gold for labels, white for values).

**Key points:** We used `UI::Begin` with a boolean reference to allow closing. Specifically, ImGui can use a bool to keep track of window open state. We also used `UI::Text` for output and a `UI::Button` for an interactive element. This example shows how to mix game data retrieval with UI drawing. It’s a template for many overlay tools – e.g., a plugin that shows live statistics would similarly gather data each frame and display via UI in `RenderInterface()`.

### Example 3: Gameplay Enhancement Plugin (Checkpoint Logger)

**Type:** Gameplay mod / logging tool – Monitors game events (like checkpoints) and logs or reacts to them.

For this example, we’ll create a plugin that logs the times at which you hit checkpoints during a race. It won’t modify gameplay, just record information. This involves detecting when a checkpoint is passed. There isn’t a direct callback for checkpoint, but we can infer it by watching the player’s checkpoint count.

**Approach:** We can use the `Update(dt)` function to periodically check the player’s checkpoint count from the game state. Trackmania’s `CSmPlayer` (or related) likely has a field for current checkpoint index or count of checkpoints passed. An easier approach is to use the `MLFeed::RaceData` plugin (if available) – but let’s assume we do it manually for learning purposes.

Pseudo-code:

* On each update, if we have a valid `app.CurrentPlayground` and a player object, check the `player.CurrentLapCheckpointIndex` or similar field. If it increased compared to last frame, a new checkpoint was passed.
* Log the time (maybe using the game’s timer or a high-resolution timer from Openplanet).

We have to find the correct property. The game’s script API might have `GamePlaygroundScript` with something like `GameTime` or checkpoint info. However, Openplanet provides `PlayerState` via *VehicleState plugin*, and also `CGamePlaygroundUI`. For simplicity, let’s say the game has `CGamePlayground` -> `GameTerminals[0]` -> `ControlledPlayer` as the player object, and that player might have a field `CurCP` we can use (in older TM, there was something like `CurrentCheckpoint` count).

Without over-complicating, we’ll use a dummy approach: count how many times the checkpoint count increases.

```cpp
// info.toml
/*
name = "CheckpointLogger"
author = "YourName"
version = "1.0.0"
description = "Logs checkpoint times for each run."
*/
uint lastCPCount = 0;
bool raceActive = false;
array<uint> cpTimes;  // store times in milliseconds

void Update(float dt) {
    CGameCtnApp@ app = GetApp();
    if (app is null) return;
    auto playground = app.CurrentPlayground;
    if (playground !is null) {
        // Get the UI or game state for times
        auto pgScript = playground.Interface; // PlaygroundScript interface (if exists)
        // Alternatively, use a placeholder for current race time:
        uint raceTime = playground.GameTime; // assume GameTime is current race time in ms
        // Get player checkpoint count
        uint cpCount = playground.CurrentCheckpointCount; // hypothetical property
        if (!raceActive && playground.GameTerminals.Length > 0) {
            raceActive = true;
            lastCPCount = 0;
            cpTimes.RemoveRange(0, cpTimes.Length); // clear previous
            print("New race started – logging checkpoints.");
        }
        if (raceActive) {
            if (cpCount > lastCPCount) {
                // Passed a new checkpoint
                uint cpIndex = cpCount;
                cpTimes.InsertLast(raceTime);
                print("Checkpoint " + cpIndex + " at time " + FormatTime(raceTime));
                lastCPCount = cpCount;
            }
            // If race finished (for simplicity, detect if respawn to 0 or something)
            if (playground.GameTerminals[0].FinishTime > 0) {
                // Race finished
                raceActive = false;
                PrintCheckpointSummary();
            }
        }
    } else {
        raceActive = false;
    }
}

string FormatTime(uint timeMs) {
    uint minutes = timeMs / 60000;
    uint seconds = (timeMs / 1000) % 60;
    uint millis  = timeMs % 1000;
    return Text::Format("%01d:%02d.%03d", minutes, seconds, millis);
}

void PrintCheckpointSummary() {
    print("Race complete! Checkpoint times:");
    for (uint i = 0; i < cpTimes.Length; i++) {
        print(" CP" + (i+1) + ": " + FormatTime(cpTimes[i]));
    }
}
```

**Disclaimer:** The above relies on some assumed properties (`CurrentCheckpointCount`, `GameTime`, etc.) that may not exactly match the real API. In real development, you'd look up the correct fields (for example, `CGamePlaygroundUI` might have `RaceTime` and the player object might have a method to get checkpoint count). The focus here is on the logic: detecting new checkpoints and logging times.

**Explanation:** When a race starts, we reset state. Each frame in Update, if a new checkpoint count is detected (cpCount > lastCPCount), we log the current race time. We accumulate times in an array. When the race finishes (we guess by checking if a finish time is recorded for the player – one way to detect finish), we output a summary of all checkpoint times. The times are formatted mm\:ss.mmm for readability.

**Usage:** This plugin would print in the log something like:

```
New race started – logging checkpoints.
Checkpoint 1 at time 0:30.125
Checkpoint 2 at time 0:55.672
Checkpoint 3 at time 1:20.900
Race complete! Checkpoint times:
 CP1: 0:30.125
 CP2: 0:55.672
 CP3: 1:20.900
```

This can help a player see how they progressed between checkpoints.

**Key points:** We demonstrated a practical gameplay-related use: reading game state continuously and reacting when certain conditions are met. We used a utility function to format time (taking advantage of `Text::Format` which is similar to C `sprintf` style). We also handled starting and finishing of a race by tracking a `raceActive` flag and resetting on new race.

In reality, you might refine this by hooking into better signals (Openplanet’s MLFeed plugin can directly give CP events, which is more reliable). But the general pattern of state monitoring in `Update()` is applicable to many scenarios (e.g., auto-respawn plugins might check if the car is upside down or not moving for X seconds and then call a respawn function, etc.).

### Best Practices and Development Tips

Finally, let's cover some general advice for developing Openplanet plugins efficiently and sustainably:

* **Use Version Control:** It’s highly recommended to use a version control system like Git for your plugin code. You can initialize a Git repository in your plugin folder (ignore the `OpenplanetNext` parent, just track your plugin’s files). This lets you experiment freely and revert if something breaks. If you choose to open source your plugin, hosting it on GitHub or GitLab also enables others to give feedback or contributions. The Openplanet community often shares code on GitHub, and there are example plugins available that you can learn from.

* **Follow Coding Conventions:** While there’s no strict enforcement, maintaining a consistent style (naming, indentation, etc.) will make your code easier to read and maintain. For example, many script authors prefix global variables with `g_` or static with `s_` to distinguish them. Choose a convention that makes the scope and purpose clear. Also, use comments to explain non-obvious logic, especially any workaround or hack needed due to API limitations.

* **Performance Considerations:** Keep an eye on how much work your plugin does per frame. Trackmania can run at hundreds of FPS on high-end PCs; your `Update()` and `Render()` functions are called at that rate. A few math calculations or checks per frame are fine, but avoid heavy file I/O, network calls, or complex loops every frame. If you need to do something expensive, consider doing it in stages, spreading over multiple frames (using yields) or doing it on an interval (e.g., only every 100ms). Also, if you use `yield()` in loops, prefer `yield()` (which yields one frame) inside the main game loop, but for timers, `sleep(ms)` is more straightforward (though keep in mind `sleep(16)` is roughly one frame at 60 FPS).

* **Threading and Async:** AngelScript in Openplanet runs your plugin essentially on the main thread (or a script thread tied to it). There’s no direct multi-threading API for scripts, but you can achieve async behavior by splitting tasks and using yields. If you do a `Net::HttpGet`, you don't block the game because you yielded until it finished. That request is handled asynchronously under the hood by Openplanet. Similarly, file reads could be done gradually if needed. So, structure your code to take advantage of the game’s frame loop for concurrency, rather than trying to spin up threads (which you cannot directly do in AngelScript).

* **Reusing Code and Libraries:** Before writing something from scratch, check if the Openplanet community has an existing solution. For instance, we mentioned MLFeed for race events, VehicleState for car telemetry, NadeoServices for auth – these are essentially libraries (as dependency plugins) provided to you. Use them instead of reinventing the wheel. You can declare dependencies in `info.toml` (e.g., `dependencies = ["MLFeed"]` or similar) and then call their functions once installed. This encourages modular design and you benefit from updates they make. Just be sure to **list the dependency** or your plugin might break when loaded alone.

* **Testing in Various Scenarios:** Try your plugin in different game modes (solo, online, relay) if applicable. Some APIs behave slightly differently online vs offline. For example, `RootMap` might be null in online but not offline. Or `LocalPlayerInfo.Name` might return your display name in solo but include club tag online – minor differences that could affect formatting. If you can, test with friends or ask the community to try pre-release versions to catch issues.

* **UI/UX Considerations:** If your plugin has a UI, consider how the user will interact with it. Make sure windows have proper titles, use consistent color codes (Trackmania’s style uses `$FFF` for white text, etc.), and do not clutter the screen. If your plugin is always drawing (like a HUD), consider providing an on/off toggle or only show it when relevant. Respect that users might have many plugins; don’t take over the entire overlay or use a bunch of hotkeys that could conflict (Openplanet lets users rebind overlay keys, but within your plugin if you use keyboard input, allow customization or choose uncommon keys).

* **Documentation and Support:** Write a README for your plugin (especially if publishing). On the Openplanet site plugin page, describe how to use it, any commands or settings, and what it’s supposed to do. This will reduce confusion and help users (and yourself, if you come back to the code after months). If you’re active in the community, be prepared to support your plugin – answer questions, fix bugs, etc., as needed. This fosters a good reputation and ensures your plugin remains useful as the game evolves.

* **Stay Updated:** Trackmania updates (or Openplanet updates) could change the API. Subscribe to Openplanet’s Discord or announcements to know when a game update might require plugin adjustments. Openplanet usually tracks game versions and provides a changelog. When updates drop, test your plugin again. For example, Nadeo might add new blocks or change class structures, which could break assumptions in your code – being proactive helps maintain compatibility.

* **Safety and Ethics:** As a plugin developer, you have a lot of power over the user’s game experience. Always prioritize the user’s system safety: don’t attempt to read or write outside permitted areas, and certainly do not include malicious code. Also, avoid automating anything that could be considered cheating in an online context. Openplanet explicitly prohibits plugins that give unfair advantages in multiplayer, and such plugins would not pass review. Stick to creative or quality-of-life enhancements, or things that are client-side only. If in doubt, ask in the community whether a plugin idea is acceptable.

* **Examples and Learning:** If you want to learn more, check out existing Openplanet plugins for Trackmania. Many authors open source their work. For instance, see the Openplanet GitHub organization and other community GitHubs for repositories named after plugins. Studying these can teach you clever tricks and optimal practices. The Openplanet documentation site also has a **“Tutorial: Writing plugins”** and other guides that we referenced, which can offer insight and snippets.

By following these guidelines and leveraging the powerful Openplanet API, you should be able to build robust and exciting plugins for Trackmania 2020. Whether it’s a heads-up display, a game mode, a training tool, or integration with web services, the possibilities are vast. Use this report as a reference as you code, and don’t hesitate to refer to the official docs and community forums for additional help. Happy coding, and we look forward to seeing the creativity of your plugin in the Trackmania community!