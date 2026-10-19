# BulletSurf guidelines

- Use GDscript and Godot conventions.
- Prefer small, single-responsibility scripts and components for them.
- Preserve existing formatting and naming conventions.
- Do not commit or push anything on the projects git repo (not your internal one).
- Ask Questions if you need more context on a feature design wise or for decision making/laking context.
- Use early Returns and continue as one-liners for readability (e.g., `if !camera: return` instead of multi-line if/return)
- Keep early returns focused on one responsibility each (avoid chaining multiple conditions with OR in one line, split into separate early returns instead)
- Leave a blank line between early return blocks and the remaining function body for visual separation
- Extract logical blocks into descriptive functions to reduce nesting and improve readability
- Keep Method scope small and readable, refactor for it when needed
- Don't comment every step in the code, just comment if ist really necessary and on the top of each script on what it intends to do

## Code Organization

- Header comment comes first at the top of the script
- Constants come after the header comment
- Signals come after constants, followed by enums
- Then @export variables organized as: references (Node, NodePath), then tweakables (floats, settings), then cached variables
- Separate export sections with empty lines, no section comments
- Then regular variables
- Place setter/getter functions at the bottom of the script
- No functions between variable declarations and the rest of the script
- Suggest removing unused variables once when you find them
