// Global flag to track if our plugin's window should be open or closed
bool windowOpen = false;

// This function is called by Openplanet to draw items in its "Plugins" menu
void RenderMenu() {
    // Add a menu item labeled "Club Room Creator"
    // The "" means no specific hotkey is assigned yet
    // 'windowOpen' is passed by reference, making it a checkable menu item
    if (UI::MenuItem("Club Room Creator", "", windowOpen)) {
        // If the item is clicked, UI::MenuItem returns true.
        // We then toggle the 'windowOpen' state.
        windowOpen = !windowOpen;
    }
}