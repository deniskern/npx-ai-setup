# Learnings

> Curated session learnings from /reflect. Persistent across updates — generate.sh never touches this file.
> After /reflect: run `/apply-learnings` to distribute entries into the correct project files. Applied entries move to `## Applied`.

## Applied
_Entries moved here after /apply-learnings has incorporated them into their target files._

- ~~`/research` muss Kandidaten gegen CONCEPT.md und Projektphilosophie validieren BEVOR Specs erstellt werden~~ → `.claude/rules/general.md` (Research & Spec Gate)
- ~~`session-optimize` Findings IMMER gegen aktuellen File-State verifizieren bevor Spec erstellt wird~~ → `.claude/rules/general.md` (Research & Spec Gate)
- ~~Stack-spezifische Skills gehören in Boilerplate-Repos, nicht in Base-Setup~~ → `.agents/context/ARCHITECTURE.md` (Directory Ownership)
- ~~Dev-Tools gehören in .claude/, nicht in templates/~~ → `.agents/context/ARCHITECTURE.md` (Directory Ownership)
- ~~SubagentStart und SubagentStop sind valide Claude Code Hook-Types~~ → `.agents/context/ARCHITECTURE.md` (Key Patterns)
- ~~claude-mem Observations können auf Worktree-Files referenzieren~~ → `.claude/rules/agents.md`
- ~~Skills mit `disable-model-invocation: true` UND ohne `model:` erben Parent-Session-Modell~~ → `.claude/rules/agents.md`
