# Phase 1 Data Model: Subscription Form

No persisted entities. This feature introduces one **transient UI state** type; the persisted `Subscription` and its rules belong to `subscriptions-core`.

---

## `SubscriptionFormMode`

`add` | `edit` — derived from whether the controller was seeded with an existing `Subscription`.

## `SubscriptionFormState` (transient)

Immutable; held by `SubscriptionFormController`. Field values are UI-friendly (e.g. amount as text) and converted to a `SubscriptionDraft` on submit.

| Field | Type | Notes |
|-------|------|-------|
| `mode` | `SubscriptionFormMode` | add / edit |
| `editingId` | `int?` | the subscription id when editing |
| `name` | `String` | service name input |
| `amountText` | `String` | raw text; parsed/validated on submit |
| `currency` | `Currency` | default TRY |
| `billingPeriod` | `BillingPeriod` | default monthly |
| `nextRenewalDate` | `DateTime` | default today |
| `category` | `SubscriptionCategory?` | null = auto from brand, else override |
| `startDate` | `DateTime?` | optional |
| `notes` | `String?` | optional |
| `isSubmitting` | `bool` | disables save, shows spinner |
| `errorMessage` | `String?` | Turkish message from the last failed submit/delete |
| `saved` | `bool` | set true on success → screen pops |

### Derivations
- **Brand preview**: `BrandResolver().resolve(name)` → `BrandCatalogEntry?` (drives the avatar + auto category default).
- **Amount parsing**: `amountText` → `double?` (comma or dot decimal); empty/invalid handled by the validator's "amount > 0" rule.

### Seeding (edit)
From an existing `Subscription`: `name`, `amount→amountText`, `currency`, `billingPeriod`, `nextRenewalDate`, `category`, `startDate`, `notes`, `editingId=id`, `mode=edit`.

---

## Submit / delete flow (controller)

```
submit():
  isSubmitting = true; errorMessage = null
  draft = SubscriptionDraft(name, parsedAmount, currency, period, date, category, startDate, notes)
  result = mode == add ? addSubscription(draft) : updateSubscription(editingId!, draft)
  result.when(
    success: () => saved = true,
    failure: (e) => errorMessage = e.message,   // ValidationError / LimitReachedError / StorageError
  )
  isSubmitting = false

delete():            // edit mode only, after confirm
  result = deleteSubscription(editingId!)
  success → saved = true ; failure → errorMessage = e.message
```

> All rules (required fields, amount > 0, currency, free-tier limit, brand enrichment) live in the core use cases — the controller does not re-implement them. `parsedAmount` falls back to a sentinel (e.g. 0/`NaN`) when the text is unparseable so the core validator rejects it with the proper Turkish message.

---

## Validation messages (from core, surfaced here)

| Trigger | Message (from core) |
|---------|---------------------|
| Empty name | "Servis adı boş olamaz." |
| Name too long | "Servis adı çok uzun." |
| Amount ≤ 0 / unparseable | "Tutar sıfırdan büyük olmalı." |
| Unsupported currency | "Desteklenmeyen para birimi." (not reachable via constrained picker) |
| Notes too long | "Not çok uzun." |
| Free limit (add) | "Ücretsiz sürüm sınırına ulaştınız." |
| Storage failure | "Veriler kaydedilirken bir sorun oluştu." |
