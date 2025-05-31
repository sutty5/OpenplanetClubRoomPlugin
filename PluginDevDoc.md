Developing an Openplanet Plugin for Trackmania Club Room Creation

Introduction

Trackmania (2020) “Club Rooms” let players host custom online servers for their club’s members or the public. Using the Openplanet modding platform, we can create a plugin that provides an in-game UI to create and configure these Club Rooms without using external websites or manual server setup. This guide will walk through setting up the Openplanet development environment, using the Openplanet API (in AngelScript) to build an in-game UI for room configuration, and leveraging official Trackmania web services (the Ubisoft/Nadeo APIs) to create rooms, select tracks, and adjust settings. We will also cover how to search and filter tracks (by style or keywords), randomly select tracks, exclude tracks already played, and pick tracks from the user’s map pool – all within the game.

Prerequisites: You should have Trackmania Club Access (only Club Access accounts can create/edit club roomswiki.trackmania.io) and have Openplanet installed in your Trackmania 2020 game. Familiarity with basic programming (C++/C# style) will help, as Openplanet plugins are written in AngelScript (a C++-like scripting language)steamcommunity.com. No prior experience with Trackmania’s APIs is required – this guide is beginner-friendly and comprehensive.



Setting Up the Openplanet Development Environment

1. Install Openplanet for Trackmania: If you haven’t already, download and install the Openplanet mod for Trackmania. Openplanet is the platform that will run our plugin inside the game. Go to the official Openplanet download page and run the latest installersteamcommunity.com. During installation, select your Trackmania install folder (the folder containing Trackmania.exe) when promptedsteamcommunity.com. Once installed, launch Trackmania – you should see an Openplanet notification in the top-right of the game confirming it’s loadedsteamcommunity.com. Press F3 in-game to open the Openplanet overlay menusteamcommunity.com (this overlay is how you browse plugins and access dev tools).

2. Enable Developer Mode: By default, Openplanet only runs signed plugins. To test your own plugin code, you need to enable Developer Signature Mode, which allows running un-signed local plugins during development. In the Openplanet in-game overlay, go to Openplanet → Signature Mode → Developer and select itopenplanet.dev. After switching to Developer mode, Openplanet will allow our custom plugin script to load. (Ensure you’re not in any online servers when using Developer mode – this mode is meant for offline development and might restrict online play for safety.)

3. Organize your Development Files: Openplanet will load any AngelScript plugin files placed in its plugins directory. Locate the Openplanet plugins folder. If you installed via the installer, this is typically at %USERPROFILE%/OpenplanetNext/Plugins or in the Trackmania installation directory under an Openplanet folder (check Openplanet’s documentation for the exact path if needed). Create a subfolder for your plugin, for example ClubRoomCreator, to keep your files organized. Inside this folder, you will create:



One or more .as script files containing your plugin code (AngelScript source). Openplanet will compile these at runtime.

An info.toml file with metadata (plugin name, author, version) and any dependencies or permissions required.

(Optional) any additional resources or data files your plugin needs (not likely needed for this simple plugin, but you might include e.g. a list of game mode definitions).

4. Set Up an Editor (optional but recommended): You can write AngelScript in any text editor, but using Visual Studio Code with an Openplanet AngelScript extension can provide syntax highlighting and code completiongithub.com. If using VSCode, consider installing the “Openplanet Angelscript” extensionmarketplace.visualstudio.com, which recognizes Openplanet’s API and AngelScript syntax. This can make development easier but is not required.

5. Understand AngelScript Basics: AngelScript is very similar to C++/C#, so basic syntax (curly braces, semicolons, variables, functions, etc.) will feel familiarsteamcommunity.com. If you’d like a quick primer, see Openplanet’s “Angelscript overview” tutorial (on openplanet.dev) for simple examples. Key points:



AngelScript code runs inside Trackmania’s process via Openplanet.

You have access to the Openplanet API – a set of classes and functions to interact with the game and UI, as documented on openplanet.dev.

Openplanet plugin code uses specific callback functions (like void Main(), void RenderMenu(), void Render() etc.) that Openplanet looks for and calls at the appropriate times.

With Openplanet installed and Developer mode on, you’re ready to start coding the plugin.



Plugin Structure and Openplanet UI Integration

An Openplanet plugin typically consists of a few core parts:



Entry point (Main) – executed when the plugin loads. We’ll use it to initialize things, such as preparing authentication for web APIs.

UI callbacks – functions called every frame to draw your plugin’s user interface. We will use these to create menus and windows via Openplanet’s UI system.

Event handlers or other loops – for ongoing tasks or responding to game events, if needed.

Let’s set up a basic structure for our Club Room Manager UI:

1. Creating a Menu Entry: We want the user to open our plugin’s interface easily from the game. We can add an item under the Openplanet “Plugins” menu. Openplanet provides a callback void RenderMenu() specifically to insert menu items (this function is called every frame to build the plugin menu)openplanet.dev. Inside RenderMenu(), use the UI::MenuItem function to create a clickable menu entry. For example:



angelscript

CopyEdit

bool windowOpen = false; // a global flag to toggle our main window



void RenderMenu() {

// Add a menu item "Club Room Creator" under Openplanet's Plugins menu

if (UI::MenuItem("Club Room Creator", "", windowOpen)) {

// Toggle the window open/closed when menu item is clicked

windowOpen = !windowOpen;

}

}

In UI::MenuItem(label, hotkey, selected), the third parameter (windowOpen) makes it a checkable item (it will show a tick when true), and the function returns true when the user selects the menu itemgit.virtit.fr. In the above snippet, clicking "Club Room Creator" flips windowOpen to show or hide the UI window.



Note: Openplanet’s UI API is built on Dear ImGui (immediate-mode GUI) under the hood, providing many widgets and windows for plugin interfacesopenplanet.dev. The UI:: namespace functions correspond to ImGui elements (e.g., UI::Text(), UI::Button(), UI::InputText(), etc.) to build interactive UIs.

2. Creating the Main UI Window: We’ll create a window that appears when windowOpen is true. Openplanet calls another callback, usually void Render() or void RenderInterface(), every frame to allow drawing your plugin’s interface. We can implement Render() to draw our ImGui window:



angelscript

CopyEdit

void Render() {

if (!windowOpen) return; // only draw if the window should be open



// Begin a new ImGui window

UI::Begin("Club Room Creator", windowOpen, UI::WindowFlags::AlwaysAutoResize);



// (Inside here we will add UI elements for room settings, track selection, etc.)



UI::End(); // end the window

}

The call UI::Begin("Club Room Creator", windowOpen, flags) creates a window titled “Club Room Creator”. We pass windowOpen by reference so that if the user closes the window (e.g. clicks an X), Openplanet can update our flag to false. We also use AlwaysAutoResize so the window fits its contents. Between Begin and End, we can add any UI widgets we need for configuration.

3. Building the Form – Room Settings and Track Selection: Now, inside the window, we will layout various controls:



Club Selection (if needed): If the player is a member of multiple clubs, we may need to choose which club to create the room in. For simplicity, we might assume the intended club is already known (perhaps the user’s primary club). In a full implementation, you could list the user’s clubs via the API (using GET /api/token/club/{playerid}/clubs to get “your clubs”webservices.openplanet.dev) and let them pick one. In our guide, we’ll assume one target club or skip this UI for brevity.

Room Name and Privacy: Provide an input field for the Room Name (e.g., UI::InputText("Room Name", roomName);). Optionally, a checkbox or dropdown for privacy (Public vs Private passworded). If password support is desired, include another InputText for a password.

Game Mode Selection: Offer a dropdown (combo box) to choose the game mode script. Trackmania’s common modes include Time Attack, Rounds, Cup, Laps, Team, Royal, etc. We can populate a combo with mode names. When a mode is selected, we should use the corresponding script ID in the API call. For instance, “Time Attack” corresponds to the script TrackMania/TM_TimeAttack_Online.Script.txt (Openplanet’s Better Room Manager plugin contains a list of mode script identifiers in its GameModes.csv, mapping friendly names to script IDs). For our UI, a simple list of modes by name is fine, but under the hood we will send the correct mode code.

Example:



angelscript

CopyEdit

string[] gameModes = { "Time Attack", "Rounds", "Cup", "Laps", "Royal" };

int selectedModeIndex = 0;

if (UI::BeginCombo("Game Mode", gameModes[selectedModeIndex])) {

for (int i = 0; i < int(gameModes.Length); i++) {

bool isSelected = (i == selectedModeIndex);

if (UI::Selectable(gameModes[i], isSelected)) {

selectedModeIndex = i;

}

if (isSelected) UI::SetItemDefaultFocus();

}

UI::EndCombo();

}

This ImGui pattern opens a combo box and allows selection. The chosen mode name can later be mapped to the actual script identifier when creating the room.

Mode Parameters: Depending on the selected game mode, allow the user to configure relevant script settings. For Time Attack, a common setting is Time Limit (e.g. 5 minutes by default). For Rounds or Cup, settings include Number of Rounds, Points to Win, etc. We will create input controls for these. To keep it simple, we might display a generic list of parameters with their default values and let users change them. For example, if Time Attack is chosen, show an integer slider or input for "Time Limit (seconds)". If Rounds is chosen, show inputs for "Rounds per Map" and "Points to Win".

We can find default values from official defaults or Openplanet community data. (The Better Room Manager plugin can load default script options and even hidden optionsgithub.comgithub.com. For our guide, we’ll assume basic known settings.)

Example for Time Attack:



angelscript

CopyEdit

int timeLimitSeconds = 300; // default 5 minutes

UI::InputInt("Time Limit (sec)", timeLimitSeconds);

if(timeLimitSeconds < 0) timeLimitSeconds = 0;

We would repeat for other settings as needed for each mode, possibly showing/hiding fields based on the mode.

Track Search and Selection: This is a major portion of the UI. We need to let the user build a map list for the room. We’ll support multiple ways:

Search by Name/Keyword: Provide a text box for a search query and a “Search” button. When clicked, we will query a track database for maps matching the keyword. Trackmania’s official API does not offer a global search by name for user-created maps. However, the community Trackmania Exchange (TMX) API can be used for this purpose. TMX’s API allows searching maps by name, author, tags, difficulty, etc. (It requires setting a custom User-Agent header and returns JSON dataapi2.mania.exchange). If we use TMX, the plugin would send an HTTP request to api2.mania.exchange/Search with the query and parse results. For demonstration, assume we implement a search that fetches e.g. the top 50 results for the keyword. We can then list those results (by map name and author) in a selectable list for the user.

Implementation detail: Perform the search in a separate thread or asynchronous task (Openplanet supports asynchronous HTTP via NadeoServices::Get or using Net::HttpRequest). Populate a list like searchResults with the returned maps. In the UI, if searchResults is non-empty, display them, e.g.:



angelscript

CopyEdit

for (uint i = 0; i < searchResults.Length; i++) {

auto map = searchResults[i];

if (UI::Selectable(map.name + " by " + map.author, false)) {

AddMapToSelection(map);

}

}

where AddMapToSelection adds the map to our final chosen list.

Filter by Track Style: Many Trackmania maps are labeled with a style (Tech, FullSpeed, Dirt, etc.). While the official Nadeo services don’t explicitly store a “style” field for each map (the mapStyle field is often emptywebservices.openplanet.dev), the TMX search can filter by tags or titlepack. We can include a dropdown for style, e.g., “Any Style, Tech, FullSpeed, Dirt, RPG, etc.” Selecting a style would narrow the search results (the plugin can include this as a filter in the TMX API query).

Random Map Selection: Provide an option to add a random set of maps. For example, a spinner or input to choose Number of Random Maps (1–100) and a button “Add Random”. When clicked, the plugin can retrieve a set of random maps from a source:

If using TMX – TMX has a “Random Map” API or we can fetch a bunch of maps by random IDs. Another approach is to take the search results (if a search was performed) and randomly pick from those.

If focusing only on the user’s own maps – we could randomize from their local map pool (see next bullet).

For demonstration, suppose the user enters “10” and clicks Add Random. We could call the TMX random map API to fetch one random map 10 times, or use an available bulk-random endpoint if provided. Each fetched map would be added to the selection list. (Better Room Manager implements adding random TMX maps within constraints like length and difficultygithub.com.)

Exclude Maps Already Played: If technically feasible, we want to avoid suggesting tracks the user has already played. This is challenging because Trackmania’s official API doesn’t provide a straightforward “list of maps I have played” for user-created maps. A heuristic approach: if using TMX, the plugin could store a local history of maps the user added to rooms or played via this plugin and omit those on random selection. Another approach is to leverage Trackmania’s records API – for any candidate map, check if the user has a recorded time on it (indicating they’ve played it). The Nadeo Records API (GET .../map/{mapId}/world-record?accountId=...) might allow checking if the user has a personal record on that mapgist.github.com. However, this works reliably only for maps that have official leaderboards (e.g., campaign or TOTD maps). For arbitrary maps, that data may not exist. So this feature might be limited. If implemented, the plugin can automatically filter out any map where the user’s account appears in its record list (or any known played list). We mark this feature as optional/experimental due to these limitations.

Selecting from User’s Map Pool: We should allow the user to pick maps they have readily available. This includes maps in their local folders (for example, maps they created or downloaded, located in the Documents/Trackmania/Maps directory). We can use Openplanet’s file I/O to list these files. The IO::IndexFolder function can list files in a given directoryopenplanet.dev. For instance:



angelscript

CopyEdit

string userMapsDir = IO::FromStorageFolder("Maps"); // or a fixed path

auto files = IO::IndexFolder(userMapsDir, true);

for (uint i = 0; i < files.Length; i++) {

if (!files[i].IsFolder && files[i].name.EndsWith(".Map.Gbx")) {

// list this map as selectable

if(UI::Selectable(files[i].name, false)) {

AddLocalMap(files[i].name);

}

}

}

In the UI, you might provide a button “Browse Local Maps” that triggers displaying a list of .Map.Gbx files found in the user’s maps folder, which they can then click to add. The Openplanet overlay file browser (under System → Folders in the Openplanet menu) can also help users find their map paths, but our plugin can list them directly. Once a local map is chosen, we will later upload it to Nadeo servers if needed (when creating the room).

All these UI elements – text inputs, combo boxes, selectable lists – can be arranged in the window using ImGui layout helpers. Keep paragraphs of text short and use tooltips or help text to explain options where needed. For example, we can add UI::TextWrapped("Select up to 100 maps...") for instructions and perhaps use UI::Separator() to group sections of the form.



Integrating with Trackmania’s APIs (Club Rooms and Maps)

With the UI allowing the user to input all desired settings, the next step is to actually create the Club Room using Ubisoft Nadeo’s web services. Trackmania 2020 does most of its online features via Web APIs (HTTP endpoints). Openplanet provides a convenient way to call these APIs from our plugin, using the player’s authentication (so we don’t need the user to re-enter credentials).

1. Authenticating to Nadeo Services: Trackmania’s APIs require an access token in the HTTP Authorization header for each request. Since our plugin runs in-game, we can utilize the fact that the game is already authenticated. Openplanet includes a built-in NadeoServices plugin that exposes the game’s auth tokens for use in our callsopenplanet.dev. We must declare dependency on NadeoServices (usually in info.toml with a line like Dependencies = ["NadeoServices"]). This ensures the NadeoServices module is loaded.

In our AngelScript code, we then call:



angelscript

CopyEdit

void Main() {

NadeoServices::AddAudience("NadeoLiveServices");

// If we also need the core API (for map info/upload), add NadeoServices too:

NadeoServices::AddAudience("NadeoServices");


// Wait until the game has provided the tokens

while(!NadeoServices::IsAuthenticated("NadeoLiveServices")

|| !NadeoServices::IsAuthenticated("NadeoServices")) {

yield();

}

// Now we have authentication tokens ready to use for API calls.

}

Here we request two “audiences”: NadeoLiveServices (needed for most Live API calls like clubs/rooms) and NadeoServices (needed for Core API calls like map upload)webservices.openplanet.dev. The game will provide tokens for these (Openplanet handles the behind-the-scenes exchange). We wait (using yield() in a loop) until IsAuthenticated(...) returns true, meaning the token is availablegithub.com. After that, we can make HTTP requests through the NadeoServices interface.

2. Using NadeoServices HTTP Functions: Openplanet’s API offers functions like NadeoServices::Get() and NadeoServices::Post() that automatically include the correct auth header in the requestopenplanet.dev. This saves us from manually attaching Authorization: nadeo_v1 t=<token> and managing token refresh. For example:



angelscript

CopyEdit

string clubId = "12345"; // The club ID in which to create the room

Json::Value roomConfig = Json::Object(); // JSON object for the request body

roomConfig["name"] = roomName;

roomConfig["script"] = selectedModeScript; // e.g. "TrackMania/TM_TimeAttack_Online.Script.txt"

roomConfig["mapUids"] = Json::Array(); // will fill with selected map UIDs

roomConfig["scriptSettings"] = Json::Object(); // e.g. {"S_TimeLimit": timeLimitSeconds}

...

// Convert JSON to string for sending

string reqBody = Json::Write(roomConfig);



auto req = NadeoServices::Post("NadeoLiveServices",

"/api/token/club/" + clubId + "/room", reqBody);

In the above pseudo-code:



We prepare a JSON object with the necessary data. The exact structure depends on the API. Typically, creating a club room (which is a type of club “activity”) might be done via a POST to a Club Services endpoint. (As of 2023, club-related APIs were merged into the Live API under “clubs” and “activities”webservices.openplanet.devwebservices.openplanet.dev.)

Hypothetically, the endpoint could be /api/token/club/{clubId}/activity with a JSON specifying the type "room" and its parameters. However, the Openplanet community documentation suggests a dedicated endpoint for rooms. For example, older documentation had an endpoint to GET a club room by ID (GET .../club/{clubID}/room/{roomID})webservices.openplanet.dev. By inference, a POST to /club/{clubId}/room likely creates a new room.

We include the room name, the game mode script name, an array of map UIDs, and a dictionary of scriptSettings. The keys for scriptSettings (e.g., "S_TimeLimit") depend on the mode’s script – these are usually defined in the mode’s script documentation. (For Time Attack, S_TimeLimit could be the time limit in milliseconds, etc. For simplicity, we might send seconds and the server expects seconds or converts appropriately.)

We use NadeoServices::Post("NadeoLiveServices", url, body) to send the request. The NadeoServices plugin will attach the correct Authorization: nadeo_v1 t={token} header for the NadeoLiveServices audiencewebservices.openplanet.dev.

3. Handling Map Uploads: If the user selected any local maps or maps not already on Nadeo servers, we must upload them before the room can use them. Each map in Trackmania is identified by a Map UID (a unique identifier generated when the map is saved) and by a Map ID (an identifier assigned upon upload to Nadeo). If a map isn’t uploaded, calling the room creation with its UID will fail with “Map not available on the Nadeo services”trackmania.exchange. We have a couple of options:



On-the-fly upload via API: Ubisoft’s official method to upload maps is through the club “map review” feature or via the dedicated server interface. However, Openplanet can utilize a private endpoint to upload a map file. One approach (used by community tools) is to use the Club Upload API. For instance, there may be an endpoint such as POST /api/token/club/{clubId}/map or a general upload in the core API. The Openplanet documentation references “club upload activities”, which likely relate to map uploadswebservices.openplanet.dev. Another approach as suggested by the community is to temporarily start a private room with that map via the API, which triggers the game to upload it (Better Room Manager automates this).

Using an Openplanet plugin or helper: There is an Openplanet plugin “Upload to Nadeo Services” by XertroV that simply takes the currently loaded map and uploads it to Nadeoreddit.com. We can emulate what such a plugin would do internally: read the .Map.Gbx file bytes and POST them to the appropriate endpoint with Content-Type: application/octet-stream. For example, the core Maps API might have an endpoint to upload (this is speculative, as the official API isn’t publicly documented for map uploads). Alternatively, since our plugin will create the room via the API, we may not need a separate explicit upload step: if we call the room creation endpoint with map UIDs that are not yet on the server, the request could fail. To prevent failure, we can upload first:

For each selected map, check if it has a mapId on Nadeo. How? If the map was authored by the user and never uploaded, it won’t appear in “Get authored maps”webservices.openplanet.dev or “Get submitted maps”. We could call GET /maps?mapUid=<uid> (there is a Get map info endpointwebservices.openplanet.dev) – if that returns a result, the map is on Nadeo (we can retrieve its mapId). If not found, we proceed to upload.

Use NadeoServices::Post("NadeoServices", "/api/upload/maps", fileBytes) (hypothetical endpoint) or the club-specific upload. Due to limited official documentation, an easier path is leveraging the game’s built-in behavior: if you create a club room via the official game UI with a local map, the game will upload it automatically. Since we are mimicking that via API, we must do the same. The Better Room Manager plugin explicitly notes it “will auto-upload maps to Nadeo if required”github.com.

For our guide, we’ll outline one straightforward method: utilize the map review feature. If your club has a “map review” activity (most clubs do), you can upload a map there. Nadeo’s Live API provides an endpoint for map upload activities. For example, some have used POST /api/token/club/{clubId}/activity/{uploadActivityId}/map/{mapUid} with the file content. The specifics are complex, so for simplicity:



We will attempt to create the room, and if the response indicates a map is not uploaded, we then call an Upload helper (or prompt the user to upload their maps via the game’s website or use the “Upload to Nadeo” plugin separately). In a fully automated plugin, you’d handle the upload in code.

Summary: Ensure all maps are on Nadeo servers. The plugin could integrate this step so that local maps are transparently uploaded (with perhaps a progress message). Keep in mind uploading requires the NadeoServices (core) token and uses the core API domain (prod.trackmania.core.nadeo.online). The NadeoServices::AddAudience("NadeoServices") we did covers thisgist.github.com. The upload process may involve a separate small token or boundary; refer to community resources or the “Upload Map to Nadeo” plugin if implementing for real.

4. Finalizing Room Creation: Once all maps are uploaded (each now has a mapId and is available), our plugin calls the create-room endpoint with the full configuration. Upon success, the API will return a JSON with the new Room ID and details. We can output a confirmation to the user, e.g., “Room created successfully! (Room ID 123456)”. We might also toggle the room to active status if it isn’t by default. (Club rooms can be created as inactive and then activated. There may be a field like "active": true in the JSON or a separate call to activate. Better Room Manager includes a toggle for room active statusgithub.com, indicating the API allows activating/deactivating the room.)

5. Error handling: It’s important to handle cases such as:



Missing club access (the API might return 403 Forbidden if the player doesn’t have rights to create a room in that club).

Incorrect parameters (API might return 400 Bad Request if e.g. a script setting key is wrong or a map UID is invalid).

Map upload failures.

We should output these errors to the user through the UI or log. The Openplanet log (accessible via overlay Openplanet → Logs) is useful for debugging. We can use trace("message") or error("message") in AngelScript to log infosteamcommunity.com.

Throughout the API integration, we rely on official endpoints and authentication:



Club & Room API (Live Services): Needs the NadeoLiveServices token in headerswebservices.openplanet.dev. Endpoints include getting club info, listing and creating activities (rooms), etc.

Maps API (Core Services): Needs the NadeoServices tokenwebservices.openplanet.dev. Endpoints include getting map info, and (implied) posting map data for upload.

Trackmania Exchange API (Community, optional): If we use TMX for searching maps by keyword/style, use their web API (no auth required, but must send a custom User-Agentapi2.mania.exchange as per their rules). TMX returns JSON; we’d parse it using Openplanet’s Json functions to get map names, UIDs, etc.

All API calls from AngelScript are done asynchronously relative to the game’s rendering – we typically initiate a request and yield until a response arrives, so as not to freeze the game. Openplanet’s networking (via NadeoServices::Get/Post) is asynchronous; we can poll req.Finished() or supply a callback function if supported.



Putting It All Together: Step-by-Step Plugin Workflow

Now that the pieces are described, here’s a step-by-step summary of how the plugin would operate when a user runs it:



Initialization (Main): Plugin starts, requests auth tokens for required services (Live and Core)webservices.openplanet.devgist.github.com, and awaits authenticationgithub.com. It also prepares any data structures (like mode lists, or loads any saved settings).

User Opens UI: The user presses F3 and selects Plugins → Club Room Creatorgit.virtit.fr. Our RenderMenu toggles windowOpen. Openplanet calls Render() each frame; seeing windowOpen == true, it draws the “Club Room Creator” window.

User Configures Room: In the UI, the user enters a Room Name, chooses a Game Mode, adjusts settings (time limit, etc.), and builds a track list:

They might search for “FullSpeed” and select 5 tracks from the results.

They choose a style filter “FullSpeed” to refine, or skip this.

They add 2 random maps.

They browse local maps and add one of their own.



All selected tracks are shown in, say, a multi-line text or a list “Selected Maps (UIDs or names)”. The plugin collects their map UIDs internally. (We might show just names for user clarity.)

User Creates Room: The UI includes a “Create Room” button. When clicked, our plugin code performs the following:

Disable the Create button to prevent repeat clicks and show a status (e.g., “Creating room, please wait…”).

Ensure the club ID is known (if multiple clubs, use the selected one).

For each selected map:

If it’s from TMX or search results, we likely have its Nadeo mapId if it’s already on Nadeo (TMX data sometimes provides an exchange ID, not directly Nadeo ID; we may need to call GET map info by UID to see if Nadeo knows it).

If it’s local (no Nadeo entry), upload it. Possibly call a helper function UploadMap(mapPath) that:

Reads the file bytes (IO::File reading),

Posts to an upload endpoint,

On success, returns the new mapId.

We then call Get map info by UID to retrieve the mapId (the upload might trigger the map to appear in “authored maps”).

Construct the JSON for room creation with all map UIDs (or map IDs – the API might accept either; in many contexts the UID is used to identify maps in a room config).

Include script settings as configured.

Send the POST request to create the room (using NadeoServices::Post with the Live API endpoint)webservices.openplanet.dev.

Wait for the response. If success (HTTP 200 OK or 201 Created), parse the JSON to get the new room’s details (room ID, etc.).

If any error occurs, capture the error message (the API might return a message like “Map with UID X not found” or “Unauthorized”).

Activating and Feedback: If room creation succeeded, the plugin can optionally ensure the room is set to active. Some APIs might create it active by default if requested. If not, an additional call POST /api/token/club/{clubId}/room/{roomId}/activate (for example) might be needed – this is speculative. (Better Room Manager allowed toggling active status easilygithub.com, so it likely uses such an endpoint.)

Once active, the room is live and joinable in-game.

We inform the user: “Room {roomName} created successfully in Club {clubName}! It’s now live under Online -> Clubs -> {clubName} -> Rooms.” We might list the number of maps and the mode for confirmation.

If relevant, also mention “Unplayed tracks were uploaded to Nadeo servers automatically.” All of this can be shown either in the UI (for example, a text label that appears upon success) or via an Openplanet notification (using UI::ShowNotification() if available, or simply a print to chat/game console).

Using the Room: The user can now switch to the game’s menus to see their new room in the club. They and other players can join it. Our plugin’s job is done – though we could enhance it by offering to open the room page directly or copy a join link. (Trackmania rooms have URLs like trackmania.com/club/{clubId}/room/{roomId} that could be opened in a browser; Openplanet could open an in-game browser if available, but that’s extra.)

Saving Configuration (optional): We might allow saving presets of room settings. For example, if a user often hosts a “Time Attack 5min FullSpeed” room with certain maps, we could save that config to a file and allow loading it later. This involves reading/writing a JSON or using Openplanet’s settings system. Due to scope, we mention this as a possible extension. (Notably, Better Room Manager supports saving/loading presets of room configurationsgithub.com.)

Testing and Deployment

To test the plugin locally:



Run Trackmania in Club Access account (Developer mode on in Openplanet).

Open the plugin UI (F3 menu) and try creating a room with a small number of maps (including one of your own). Watch the Openplanet log for any errors. If something fails (e.g., map not uploaded), adjust the code accordingly.

Once it works for you, you can iterate on the UI (make it prettier, ensure it’s user-friendly) – use headings, tooltips, etc. Keep the UI responsive by not doing long operations on the main thread (utilize yield() while waiting for network calls so the game doesn’t freeze).

When you’re satisfied, you can deploy the plugin by packaging it: compile to a .op file and sign it using Openplanet’s documentation guidelinessteamcommunity.com if you plan to distribute it. For personal use, running in Developer mode with source files is fine. If distributing to others, you must sign the plugin (which involves uploading it on openplanet.dev to get it approved, typically).

Installation for Users: If you distribute the plugin, users would install it by placing the .op file (and any support files like info.toml) in their Openplanet Plugins folder or via the Openplanet plugin manager. For local usage, since you are the developer, you can just keep the script in your dev environment.

Make sure to include in your documentation the requirement of Club Access and any limitations (for example, “Starter access players cannot create club rooms”). Also, emphasize that misuse of the web services (excessive requests) should be avoided – Openplanet and Nadeo expect responsible usewebservices.openplanet.dev. Our plugin is user-driven (requests occur when the user searches or creates a room), so it should be well within normal usage.



References and Resources

Openplanet Official Documentation – Plugin development basics, UI API, and Angelscript referencesteamcommunity.comopenplanet.dev. (See openplanet.dev for “Getting Started” and “Writing plugins” tutorials.)

Trackmania Web Services (Nadeo Live & Core API) – Community-documented endpoints for clubs, rooms, and mapswebservices.openplanet.devwebservices.openplanet.dev. These explain required authentication and data formats for interacting with Trackmania’s backend.

Ubisoft Trackmania Club Documentation – Overview of club features (Trackmania doc site) and Trackmania Wikiwiki.trackmania.iowiki.trackmania.io (for understanding concepts like roles, club activities).

Better Room Manager Openplanet Plugin by XertroV – This open-source plugin served as inspiration, demonstrating creating/editing rooms, adding maps (including TMX integration), and saving presetsgithub.comgithub.com. Reviewing its code and README gave insight into required API calls and plugin structure.

Trackmania Exchange API – Endpoints for searching community maps. Useful for implementing keyword search and style filters (not an official Ubisoft service, but widely used)api2.mania.exchange.

By combining the above resources and following this guide, you should be able to develop a fully functional Trackmania 2020 Club Room Creator plugin using Openplanet. This will empower users to spin up multiplayer rooms with custom tracks and settings through an intuitive in-game interface – no external website or dedicated server setup required. Good luck and happy coding!