## 2024-05-13 - O(N*M) to O(N+M) GridView Lookups
**Learning:** Found a nested loop where `GridView.builder` linearly searched a list inside `itemBuilder` (`cartItems.firstWhere`). This causes `O(N*M)` complexity on render where N is visible products and M is cart items.
**Action:** Always pre-compute a lookup `Map` outside the builder (e.g. `final map = {for (var i in items) i.id: i}`) to turn it into `O(N+M)` with `O(1)` lookups.
