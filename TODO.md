# TODO

## Companion script: `dictation-suggest-vocab`

Standalone script that scans text sources for personal vocabulary the user
might want in `~/.config/dictation/vocabulary` (passed as `keyterms` to
ElevenLabs Scribe v2 to bias transcription accuracy).

**Goal:** keep the vocabulary fresh as your projects, colleagues, and jargon
evolve, without manual curation friction.

**Output:** prints suggestions to terminal — user copies interesting ones into
the vocabulary file. **Never auto-writes** to avoid propagating transcription
errors or noise as keyterms.

### Text sources to consider

1. **`~/.local/share/dictation/sessions/sessions.jsonl`** — past dictation
   transcripts. Pros: real dictation context. Cons: ElevenLabs transcripts
   may contain errors that, if added as keyterms, lock in mistakes (e.g. a
   misheard colleague's name biases future transcripts toward the wrong
   spelling).

2. **`~/.claude/projects/`** — Claude Code conversation logs. The user-typed
   messages contain custom vocabulary (project names, colleague names,
   technical terms) in clean form, since the user *typed* them. This is a
   higher-signal source than dictation transcripts because there's no
   transcription error to propagate. Cons: includes non-vocabulary chatter
   that the suggester needs to filter.

   Likely the better default source — typed text is clean, projects-dir scope
   is naturally focused on the user's actual work.

3. **Both, weighted** — score by frequency × distinctiveness (e.g. words
   common in the user's text but rare in general English). Hybrid avoids
   either source's blind spots.

### Implementation approach (when building)

Two viable strategies:

- **TF-IDF / frequency-based extraction** — count word frequencies in source,
  compare against a common-English baseline (e.g. Wiktionary frequency list),
  surface high-distinctiveness terms. No external API. Deterministic.

- **LLM-assisted extraction** — send concatenated source text to an LLM with
  a tight prompt: "Extract domain-specific terms — names, jargon, internal
  codenames, technical terminology — that would benefit from being in a
  transcription bias vocabulary. Output one term per line, no commentary."
  Smarter filtering, costs cents per run, requires an LLM API key (would
  re-introduce a provider dependency).

For a personal tool, TF-IDF over Claude logs is probably the right starting
point: zero new dependencies, leverages the cleanest text source.

### Constraints

- ElevenLabs caps `keyterms` at 50 entries × 20 chars each.
- Must respect the user's manually-curated vocabulary file — the suggester
  prints suggestions; the user decides what to add.
- Run on demand (e.g. monthly), not in the hot path.
