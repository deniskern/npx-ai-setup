#!/usr/bin/env tsx
/**
 * storyblok-dump.ts
 * Fetches all Storyblok stories (draft) and writes a JSONL file to scripts/storyblok-dump.json.
 * Usage: npm run storyblok-dump
 * Env:   STORYBLOK_TOKEN (required), STORYBLOK_REGION (optional, default: eu)
 */

import { writeFileSync } from "fs";
import { config } from "dotenv";

config();

const TOKEN = process.env.STORYBLOK_TOKEN;
const REGION = process.env.STORYBLOK_REGION ?? "eu";
const OUTPUT = "scripts/storyblok-dump.json";
const BASE_URL =
  REGION === "us"
    ? "https://api-us.storyblok.com/v2/cdn"
    : "https://api.storyblok.com/v2/cdn";

if (!TOKEN) {
  console.error("❌ STORYBLOK_TOKEN is not set in .env");
  process.exit(1);
}

async function fetchPage(page: number): Promise<{ stories: Story[]; total: number }> {
  const url = `${BASE_URL}/stories?token=${TOKEN}&version=draft&per_page=100&page=${page}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Storyblok API error: ${res.status} ${res.statusText}`);
  const total = Number(res.headers.get("total") ?? 0);
  const data = (await res.json()) as { stories: Story[] };
  return { stories: data.stories, total };
}

interface Story {
  id: number;
  uuid: string;
  name: string;
  slug: string;
  full_slug: string;
  component?: string;
  published_at: string | null;
  updated_at: string;
}

async function main() {
  console.log("📦 Fetching Storyblok stories...");

  const first = await fetchPage(1);
  const totalStories = first.total;
  const totalPages = Math.ceil(totalStories / 100);
  let all: Story[] = [...first.stories];

  for (let page = 2; page <= totalPages; page++) {
    const { stories } = await fetchPage(page);
    all = all.concat(stories);
    process.stdout.write(`\r  Fetching page ${page}/${totalPages}...`);
  }

  console.log(`\n  ✅ ${all.length} stories fetched`);

  const lines: string[] = [
    JSON.stringify({
      _summary: true,
      total: all.length,
      generated_at: new Date().toISOString(),
      region: REGION,
    }),
    ...all.map((s) =>
      JSON.stringify({
        id: s.id,
        uuid: s.uuid,
        name: s.name,
        slug: s.slug,
        full_slug: s.full_slug,
        component: s.component ?? null,
        published_at: s.published_at,
        updated_at: s.updated_at,
      })
    ),
  ];

  writeFileSync(OUTPUT, lines.join("\n") + "\n", "utf8");
  console.log(`  📄 Written to ${OUTPUT}`);
}

main().catch((err) => {
  console.error("❌", err.message);
  process.exit(1);
});
