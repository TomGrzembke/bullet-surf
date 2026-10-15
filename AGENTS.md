# SpaceyWorld guidelines

- Use C# and Unity conventions.
- Keep gameplay scripts under `Assets/02_Scripts/`.
- Prefer small, single-responsibility MonoBehaviours.
- Do not modify `ProjectSettings/` or package files unless explicitly requested.
- Preserve existing formatting and naming conventions.
- Use serialized private fields (`[SerializeField] ...`) instead of public fields where possible.
- Avoid any unnecessary private declaration for Methods, classes, data containers etc, where its implicit anyway
- Avoid `FindObjectOfType` in runtime code; use references or dependency injection.
- Before completing a change, run the relevant Unity tests when feasible.
- Do not commit or push anything on the projects git repo (not your internal one).
- Ask Questions if you need more context on a feature design wise or for decision making/laking context.
- - Prefer `TryGetComponent` over `GetComponent` where absence is expected.
- Avoid allocations in frequently called paths such as `Update`, `FixedUpdate`, and UI refresh loops.