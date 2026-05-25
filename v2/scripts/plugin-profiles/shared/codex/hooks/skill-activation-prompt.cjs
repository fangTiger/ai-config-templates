#!/usr/bin/env node
const { existsSync, readFileSync } = require('fs');
const { join } = require('path');

function main() {
  const input = readFileSync(0, 'utf-8');
  const data = JSON.parse(input);
  const prompt = String(data.prompt || '').toLowerCase();
  const projectDir =
    process.env.CODEX_PROJECT_DIR ||
    process.env.PROJECT_DIR ||
    process.env.CLAUDE_PROJECT_DIR ||
    data.cwd ||
    process.cwd();
  const rulesPath = join(projectDir, '.codex', 'skills', 'skill-rules.json');
  if (!existsSync(rulesPath)) {
    return;
  }
  const rules = JSON.parse(readFileSync(rulesPath, 'utf-8'));

  const matchedSkills = [];
  for (const [skillName, config] of Object.entries(rules.skills || {})) {
    const triggers = config.promptTriggers;
    if (!triggers) {
      continue;
    }
    const keywordMatch = (triggers.keywords || []).some((keyword) =>
      prompt.includes(String(keyword).toLowerCase())
    );
    if (keywordMatch) {
      matchedSkills.push({ name: skillName, config });
      continue;
    }
    const intentMatch = (triggers.intentPatterns || []).some((pattern) =>
      new RegExp(pattern, 'i').test(prompt)
    );
    if (intentMatch) {
      matchedSkills.push({ name: skillName, config });
    }
  }

  if (matchedSkills.length === 0) {
    return;
  }

  const byPriority = (priority) => matchedSkills.filter((item) => item.config.priority === priority);
  let output = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';
  output += '技能触发检查\n';
  output += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n';

  const sections = [
    ['必须关注的技能：', byPriority('critical')],
    ['推荐使用的技能：', byPriority('high')],
    ['可考虑的技能：', byPriority('medium')],
    ['低优先级技能：', byPriority('low')],
  ];

  for (const [title, items] of sections) {
    if (items.length === 0) {
      continue;
    }
    output += `${title}\n`;
    for (const item of items) {
      output += `  → ${item.name}\n`;
    }
    output += '\n';
  }

  output += '动作：回复或动手前先读取匹配的 SKILL.md\n';
  output += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';
  console.log(output);
}

try {
  main();
} catch (error) {
  console.error('skill-activation-prompt hook error:', error);
  process.exit(0);
}
