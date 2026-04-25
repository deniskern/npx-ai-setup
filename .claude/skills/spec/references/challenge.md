# Challenge Gate Reference

After context-scan and before Phase 1d, present findings via one AskUserQuestion call (multiSelect):

**4 challenges to investigate first:**

1. **Existing code**: Does something already solve this? Search before implementing.
2. **Pattern conflict**: Does this fight an established pattern in the codebase?
3. **Simpler alternative**: What is the simplest approach — and why does it fall short?
4. **6-month pain**: Where will this be hardest to maintain, debug, or extend?

For each, show:
```
Challenge: [concrete statement]
Source: path/to/file:NN
Recommendation: [Weiter / Scope ändern / Ansatz überdenken]
```

Then ask:
```
AskUserQuestion({
  questions: [{
    question: "Challenge-Ergebnis: [1-Satz-Summary]. Weiter?",
    header: "Challenge",
    multiSelect: false,
    options: [
      { label: "Ja, Spec schreiben", description: "Challenges akzeptiert, weiter mit Phase 1d" },
      { label: "Ansatz anpassen", description: "Scope oder Approach überdenken — zeig Alternativen" },
      { label: "Spec abbrechen", description: "Task ist nicht sinnvoll oder zu riskant" }
    ]
  }]
})
```

Stop if "Spec abbrechen". Revise Phase 1 if "Ansatz anpassen".
