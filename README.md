# Lab Guide - Command Reference


**Branches:** `main` = the current **VCF 9.1** lab guide · [`9.0`](../../tree/9.0) = the previous VCF 9.0 lab (OpenCart-based), kept frozen for reference.

## The Problem

The lab guide is a long, screenshot-heavy document where CLI commands are buried across dozens of pages. Students frequently lose track of **which VCF/kubectl context** they should be in when running each command. A wrong context means commands silently target the wrong namespace or cluster, producing confusing errors or deploying resources in the wrong place.

The lab also involves **multiple context types** (VCFA/CCI contexts like `vcfa:dev-xxxxx` and `vks-01`, a K8S/basic-auth Supervisor context `supervisor:test-xxxxx`, plain terminal, an `argocd` CLI session, and direct `--kubeconfig` access to the vks-argo cluster without any context switch) with transitions scattered across chapters. There is no single place in the original guide that maps out this context flow.

## The Solution

This Instructor Guide is a single file reference that:

- **Prefixes every CLI command with the required context** — so you always know whether you need `vcfa:dev-xxxxx`, `vcfa:prod-xxxxx`, `vks-01`, `supervisor:test-xxxxx`, `terminal`, or an `argocd` CLI session before running a command
- **Calls out every context transition** — `vcf context create`, `vcf context use`, and `argocd login` are highlighted with annotations showing exactly what changes
- **Includes a lab overview** summarizing what each module and chapter does, which chapters have CLI commands, and the manual-then-GitOps deployment pattern
- **Hyperlinked index** for quick navigation to any chapter or sub-section
- **Page number references** back to the original lab guide for screenshots and GUI steps

This file is designed for instructors to sit alongside the original lab guide, not replace it. Use it to quickly find the next command, or commands which should have been used in which context for students, confirm you're in the right context, and understand where you are in the overall flow.

## Files

- `commandsandtasks.md` — the full instructor reference (contexts, commands, page refs, credentials, 9.0→9.1 diff table)
- `studentworksheet.md` — fill-in-the-blank tracker for pod-unique values (namespaces, IPs, passwords)
- `manifests/` — corrected/reference YAMLs (populated after first lab validation run)
