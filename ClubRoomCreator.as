// Global flag to track if our plugin's window should be open or closed
bool windowOpen = false;

// Entry point called when the plugin loads
void Main() {
    // Request authentication tokens for the required Nadeo services
    NadeoServices::AddAudience("NadeoLiveServices");
    NadeoServices::AddAudience("NadeoServices");
    // Wait until authentication is available
    while (!NadeoServices::IsAuthenticated("NadeoLiveServices")
        || !NadeoServices::IsAuthenticated("NadeoServices")) {
        yield();
    }
}

// This function is called by Openplanet to draw items in its "Plugins" menu
void RenderMenu() {
    // Add a menu item labeled "Club Room Creator"
    // The "" means no specific hotkey is assigned yet
    // 'windowOpen' is passed by reference, making it a checkable menu item
    if (UI::MenuItem("Club Room Creator", "", windowOpen)) {
        // Toggle the window when the menu item is clicked
        windowOpen = !windowOpen;
    }
}

// Draw the plugin's main window
void Render() {
    if (!windowOpen) return;
    // Simple placeholder window until further UI is implemented
    UI::Begin("Club Room Creator", windowOpen, UI::WindowFlags::AlwaysAutoResize);
    UI::Text("Plugin setup complete. Further UI will be added here.");
    UI::End();
}
