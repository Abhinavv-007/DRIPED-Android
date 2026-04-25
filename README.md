# driped

Driped — stop the drip.

## AI Mail Extraction

The Gmail scanner uses a two-tier pipeline:

1. **Deterministic parser** (`SubscriptionParser` + `@driped/scan`) handles ~85%
   of emails: sender-domain map, merchant regex templates, classifier, amount
   / date / cycle extractors. Runs entirely on device, milliseconds per email.
2. **Cloud AI fallback** for low-confidence or unknown-sender emails. The app
   POSTs the cleaned body to `POST https://api.driped.in/scan/extract`, which
   runs Llama 3.1 8B Instruct via Cloudflare Workers AI and caches per-email
   results in KV for 24 h. Rate-limited to 100 extractions / user / minute.

The previous on-device LiteRT-LM model (`mobile-actions_q8_ekv1024.litertlm`,
~270 MB) was removed in v3.1.1. The cloud fallback uses a much larger model and
ships ~570 MB lighter APKs.

Email contents leave the device only when the parser returns
`overallConfidence < 70`. Even then, only a sanitised body slice is sent and
the Worker keeps no per-user audit log.
