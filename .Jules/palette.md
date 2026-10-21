## 2026-05-28 - Add confirmation dialog for delete action
**Learning:** Users can accidentally clear their entire cart with a single misclick on the 'Kosongkan Keranjang' trash button, leading to frustration.
**Action:** Always wrap destructive actions like clearing carts or deleting items in a confirmation modal using `showShadDialog`.
