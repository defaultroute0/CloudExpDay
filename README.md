# VCF Field Demo Lab Guide - Command Reference

This repo contains a processed reference extracted from the 295-page VMware VCF Field Demo Lab Guide hosted on Broadcom's Lab Platform.

## The Problem

The lab guide is a long, screenshot-heavy document where CLI commands are buried across dozens of pages. Students frequently lose track of **which VCF/kubectl context** they should be in when running each command. A wrong context means commands silently target the wrong namespace or cluster, producing confusing errors or deploying resources in the wrong place.

The lab also involves **five different context types** (VCFA CCI, vks-01, supervisor, terminal, ArgoCD CLI) with transitions scattered across chapters. There is no single place in the original guide that maps out this context flow.

## The Solution

**[`output/commands-with-context.md`](output/commands-with-context.md)** is a single-file reference that:

- **Prefixes every CLI command with the required context** — so you always know whether you need `vcfa:dev-xxxxx`, `vks-01`, `supervisor:test-xxxxx`, `terminal`, or an `argocd` CLI session before running a command
- **Calls out every context transition** — `vcf context create`, `vcf context use`, and `argocd login` are highlighted with annotations showing exactly what changes
- **Includes a lab overview** summarizing what each module and chapter does, which chapters have CLI commands, and the manual-then-GitOps deployment pattern
- **Hyperlinked index** for quick navigation to any chapter or sub-section
- **Page number references** back to the original lab guide for screenshots and GUI steps
- **Verified against the raw HTML source** — every command was triple-checked against the original scraped lab guide

This file is designed to sit alongside the original lab guide, not replace it. Use it to quickly find the next command, confirm you're in the right context, and understand where you are in the overall flow.
