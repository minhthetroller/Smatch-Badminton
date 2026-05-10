# Match Image Upload API

## Endpoint

```
POST /api/uploads/match-image
Authorization: Bearer <firebase-jwt>
Content-Type: multipart/form-data
```

## Request

Send the image as `multipart/form-data` with field name `image`:

```typescript
async function uploadMatchImage(file: File, token: string): Promise<string> {
  const form = new FormData();
  form.append("image", file);

  const res = await fetch("http://localhost:3000/api/uploads/match-image", {
    method: "POST",
    headers: { Authorization: `Bearer ${token}` },
    body: form,
  });

  if (!res.ok) {
    const err = await res.json();
    throw new Error(err.error?.message ?? "Upload failed");
  }

  const data = await res.json();
  return data.data.url; // S3 URL to store in match.images[]
}
```

## Constraints

| Rule | Value |
|---|---|
| Field name | `image` |
| Allowed types | `.jpg`, `.jpeg`, `.png` |
| Max file size | 5 MB |
| Auth required | Yes — Firebase JWT (`RequireRegisteredUser`) |

## Success Response `201`

```json
{
  "success": true,
  "data": {
    "url": "https://smatch-matches.s3.amazonaws.com/matches/<uuid>-<ts>.jpg",
    "fileName": "photo.jpg"
  }
}
```

## Error Responses

| Status | Code | Cause |
|---|---|---|
| `400` | `BAD_REQUEST` | No file / invalid form data |
| `400` | `BAD_REQUEST` | Unsupported extension (pdf, gif, etc.) |
| `401` | — | Missing or invalid Firebase JWT |
| `503` | `UPLOAD_UNAVAILABLE` | S3 not configured server-side |
| `500` | `UPLOAD_FAILED` | S3 write error |

## Full Flow — Create Match with Images

Upload images first, collect URLs, then include them in the create-match body.

```typescript
// Step 1 — upload images
const urls = await Promise.all(files.map(f => uploadMatchImage(f, token)));

// Step 2 — create match
await fetch("/api/matches", {
  method: "POST",
  headers: {
    Authorization: `Bearer ${token}`,
    "Content-Type": "application/json",
  },
  body: JSON.stringify({ ...matchFields, images: urls }),
});
```

## Fix "No Internet Connection" Error

The error fires on any failed request, not just actual network failures. Distinguish HTTP errors from connectivity errors:

```typescript
// BAD — current behavior
catch (e) {
  showError("No internet connection"); // fires on 404 / 500 too
}

// GOOD
catch (e) {
  if (!navigator.onLine) {
    showError("No internet connection");
  } else {
    showError(e.message ?? "Request failed");
  }
}
```
